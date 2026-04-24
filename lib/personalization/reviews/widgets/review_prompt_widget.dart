import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../../main.dart';

class ReviewPromptWidget extends ConsumerStatefulWidget {
  const ReviewPromptWidget({super.key});

  @override
  ConsumerState<ReviewPromptWidget> createState() => _ReviewPromptWidgetState();
}

class _ReviewPromptWidgetState extends ConsumerState<ReviewPromptWidget> {
  bool _shouldShow = false;
  List<String> _orderedProductIds = [];
  List<ProductModel> _productsToReview = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkReviewEligibility();
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
        if (product != null) {
          products.add(product);
        }
      }

      _productsToReview = products;

      if (_productsToReview.isNotEmpty) {
        setState(() {
          _shouldShow = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissReview() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('orderDone', false);
    setState(() => _shouldShow = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_shouldShow) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardDark, AppColors.cardDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Your Purchase',
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'How was your experience with these products?',
                      style: TextStyle(color: AppColors.softGrey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.softGrey),
                onPressed: _dismissReview,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _productsToReview.length,
              itemBuilder: (context, index) {
                final product = _productsToReview[index];
                return _buildProductReviewItem(product);
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _dismissReview,
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: AppColors.softGrey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductReviewItem(ProductModel product) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.imageUrls.isNotEmpty
                ? CachedNetworkImageWidget(
                    imageUrl: product.imageUrls.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppColors.cardDark,
                    child: const Icon(Icons.image),
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
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star_border,
                      color: AppColors.accentGold,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to rate',
                  style: TextStyle(
                    color: AppColors.accentGold.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
