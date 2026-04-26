import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../../main.dart';
import 'review_dialog.dart';

class ReviewPromptWidget extends ConsumerStatefulWidget {
  const ReviewPromptWidget({super.key});

  @override
  ConsumerState<ReviewPromptWidget> createState() => _ReviewPromptWidgetState();
}

class _ReviewPromptWidgetState extends ConsumerState<ReviewPromptWidget>
    with SingleTickerProviderStateMixin {
  bool _shouldShow = false;
  List<String> _orderedProductIds = [];
  List<ProductModel> _productsToReview = [];
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _checkReviewEligibility();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkReviewEligibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderDone = prefs.getBool('orderDone') ?? false;

      if (!orderDone) {
        setState(() => _isLoading = false);
        return;
      }

      final orderedTime = prefs.getInt('orderedTime') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const twentyFourHoursInMs = 24 * 60 * 60 * 1000;

      if (currentTime - orderedTime < twentyFourHoursInMs) {
        setState(() => _isLoading = false);
        return;
      }

      _orderedProductIds = prefs.getStringList('orderedProductIds') ?? [];

      if (_orderedProductIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final productRepository = ref.read(productRepositoryProvider);
      List<ProductModel> products = [];
      for (String id in _orderedProductIds) {
        final product = await productRepository.getProductById(id);
        if (product != null) products.add(product);
      }

      _productsToReview = products;

      if (_productsToReview.isNotEmpty) {
        setState(() {
          _shouldShow = true;
          _isLoading = false;
        });
        _animController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissReview() async {
    await _animController.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('orderDone', false);
    if (mounted) setState(() => _shouldShow = false);
  }

  void _openReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReviewDialog(
        products: _productsToReview,
        onSubmitted: _dismissReview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_shouldShow) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSoft, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.07),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGold.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGold.withOpacity(0.04),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(onDismiss: _dismissReview),
                      const SizedBox(height: 18),
                      _ProductsRow(
                        products: _productsToReview,
                        onTap: _openReviewDialog,
                      ),
                      const SizedBox(height: 18),
                      _Actions(
                        onReview: _openReviewDialog,
                        onDismiss: _dismissReview,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onDismiss;
  const _Header({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentGold.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.accentGold,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate Your Purchase',
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Share your experience with these products',
                style: GoogleFonts.dmSans(
                  color: AppColors.softGrey,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.borderSoft.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.softGrey,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductsRow extends StatelessWidget {
  final List<ProductModel> products;
  final VoidCallback onTap;
  const _ProductsRow({required this.products, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) =>
            _ProductCard(product: products[index], onTap: onTap),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondaryDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.imageUrls.isNotEmpty
                  ? CachedNetworkImageWidget(
                      imageUrl: product.imageUrls.first,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.softGrey,
                        size: 20,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.productName,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.star_border_rounded,
                          color: AppColors.accentGold.withOpacity(0.6),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tap to rate',
                    style: GoogleFonts.dmSans(
                      color: AppColors.accentGold.withOpacity(0.65),
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final VoidCallback onReview;
  final VoidCallback onDismiss;
  const _Actions({required this.onReview, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onReview,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'REVIEW NOW',
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.borderSoft.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft, width: 0.5),
            ),
            child: Center(
              child: Text(
                'Later',
                style: GoogleFonts.dmSans(
                  color: AppColors.softGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
