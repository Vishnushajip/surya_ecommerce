import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../../main.dart';
import '../../../core/widgets/app_cached_image.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final List<ProductModel> products;
  final VoidCallback onSubmitted;

  const ReviewDialog({
    super.key,
    required this.products,
    required this.onSubmitted,
  });

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  int _overallRating = 5;
  final TextEditingController _overallFeedbackController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final Map<String, int> _productRatings = {};
  final Map<String, TextEditingController> _productFeedbackControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var product in widget.products) {
      _productRatings[product.id] = 5;
      _productFeedbackControllers[product.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _overallFeedbackController.dispose();
    _nameController.dispose();
    for (var controller in _productFeedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReviews() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    // Check if overall feedback is added
    if (_overallFeedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add overall experience feedback')),
      );
      return;
    }

    // Check if all product feedbacks are added
    for (var product in widget.products) {
      if (_productFeedbackControllers[product.id]!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add feedback for ${product.productName}')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewRepository = ref.read(reviewRepositoryProvider);
      final now = Timestamp.now();
      const uuid = Uuid();

      // 1. Submit Overall Review
      final overallReview = ReviewModel(
        feedbackId: uuid.v4(),
        productId: 'overall_experience',
        rating: _overallRating,
        feedback: _overallFeedbackController.text.trim(),
        title: 'Store Experience',
        createdAt: now,
        customerName: name,
      );
      await reviewRepository.addReview(overallReview);

      // 2. Submit Product Reviews
      for (var product in widget.products) {
        final productReview = ReviewModel(
          feedbackId: uuid.v4(),
          productId: product.id,
          rating: _productRatings[product.id] ?? 5,
          feedback: _productFeedbackControllers[product.id]!.text.trim(),
          title: 'Product Review',
          createdAt: now,
          customerName: name,
        );
        await reviewRepository.addReview(productReview);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your valuable feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting reviews: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSoft),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rate_review_outlined, color: AppColors.accentGold),
                    const SizedBox(width: 12),
                    Text(
                      'Rate Your Experience',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.softGrey),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Section
                    Text(
                      'YOUR NAME',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your name...',
                        hintStyle: TextStyle(color: AppColors.softGrey.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Overall Rating Section
                    Text(
                      'OVERALL EXPERIENCE',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRatingBar(
                      rating: _overallRating,
                      onChanged: (val) => setState(() => _overallRating = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _overallFeedbackController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts about your purchase...',
                        hintStyle: TextStyle(color: AppColors.softGrey.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Product Specific Ratings
                    Text(
                      'RATE PRODUCTS',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.products.map((product) => _buildProductRatingItem(product)),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReviews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryDark,
                                ),
                              )
                            : Text(
                                'SUBMIT REVIEWS',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRatingItem(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppCachedImage(
                  url: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  product.productName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRatingBar(
            rating: _productRatings[product.id] ?? 5,
            onChanged: (val) => setState(() => _productRatings[product.id] = val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _productFeedbackControllers[product.id],
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Good quality, reasonable price...',
              hintStyle: TextStyle(color: AppColors.softGrey.withOpacity(0.3), fontSize: 13),
              filled: true,
              fillColor: AppColors.primaryDark.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar({required int rating, required Function(int) onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () => onChanged(index + 1),
          icon: Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.accentGold,
            size: 32,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      }),
    );
  }
}
