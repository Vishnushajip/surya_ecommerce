import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/data/models/review_model.dart';
import 'package:surya_ecommerce/main.dart';

class ReviewListWidget extends ConsumerStatefulWidget {
  final String productId;
  final bool isTestimonial;

  const ReviewListWidget({
    super.key,
    required this.productId,
    this.isTestimonial = false,
  });

  @override
  ConsumerState<ReviewListWidget> createState() => _ReviewListWidgetState();
}

class _ReviewListWidgetState extends ConsumerState<ReviewListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return StreamBuilder<List<ReviewModel>>(
      stream: ref.watch(reviewRepositoryProvider).streamReviewsForProduct(widget.productId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('🔥 REVIEW STREAM ERROR: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.accentGold),
            ),
          );
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          if (widget.isTestimonial) return const SizedBox.shrink();
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(reviews.length),
            const SizedBox(height: 24),
            if (widget.isTestimonial || !isMobile)
              _buildHorizontalList(reviews)
            else
              _buildVerticalList(reviews),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Text(
          "CUSTOMER REVIEWS",
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.isTestimonial) const Spacer(),
        if (widget.isTestimonial)
          Text(
            'Scroll right →',
            style: GoogleFonts.outfit(
              color: AppColors.softGrey,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalList(List<ReviewModel> reviews) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 320,
            child: _ReviewCard(review: reviews[index]),
          );
        },
      ),
    );
  }

  Widget _buildVerticalList(List<ReviewModel> reviews) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _ReviewCard(review: reviews[index]);
      },
    );
  }

 
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(review.displayName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.displayName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      review.relativeTime,
                      style: GoogleFonts.outfit(
                        color: AppColors.softGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: AppColors.accentGold, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.accentGold,
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            review.feedback,
            style: GoogleFonts.outfit(
              color: AppColors.textWhite.withOpacity(0.8),
              height: 1.5,
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
