import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../../data/models/product_model.dart';
import '../view_model/product_details_view_model.dart';
import '../../cart/view_model/cart_view_model.dart';
import '../../cart/widgets/floating_cart_sheet.dart';
import '../../reviews/widgets/review_list_widget.dart';
import '../../../routes/app_router.dart';

class ProductDetailsView extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsView({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends ConsumerState<ProductDetailsView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addToCart(ProductModel product) async {
    try {
      await ref
          .read(cartViewModelProvider.notifier)
          .addToCart(product, quantity: 1);

      ref.read(isCartHiddenProvider.notifier).state = false;

      if (mounted) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(
      productDetailsViewModelProvider(widget.productId),
    );
    final cartAsync = ref.watch(cartViewModelProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: productAsync.value?.productName.toUpperCase() ?? '',
      ),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          final isInCart =
              cartAsync.value?.items.any(
                (item) => item.product.id == product.id,
              ) ??
              false;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? MediaQuery.of(context).size.width * 0.1
                    : 20,
                vertical: 20,
              ),
              child: isDesktop
                  ? _buildDesktopLayout(product, isInCart)
                  : _buildMobileLayout(product, isInCart),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(ProductModel product, bool isInCart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildGallerySection(product)),
        const SizedBox(width: 40),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildInfoSection(product, isInCart),
              const SizedBox(height: 50),
              ReviewListWidget(productId: product.id),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ProductModel product, bool isInCart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGallerySection(product),
        const SizedBox(height: 30),
        _buildInfoSection(product, isInCart),
        const SizedBox(height: 50),
        ReviewListWidget(productId: product.id),
      ],
    );
  }

  Widget _buildGallerySection(ProductModel product) {
    return Column(
      children: [
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: product.imageUrls.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImageWidget(
                    imageUrl: product.imageUrls[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            product.imageUrls.length,
            (index) => Container(
              margin: const EdgeInsets.only(right: 10),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentPage == index
                      ? AppColors.accentGold
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImageWidget(
                  imageUrl: product.imageUrls[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ProductModel product, bool isInCart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
          ),
          child: Text(
            product.productCategory,
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          product.productName,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ..._buildRatingStars(product.ratingAverage),
            const SizedBox(width: 8),
            Text(
              "(${product.ratingCount} Reviews)",
              style: GoogleFonts.outfit(
                color: AppColors.softGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "₹ ${product.price.toStringAsFixed(0)}",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "₹ 2499",
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppColors.softGrey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if ((product.color != null && product.color!.isNotEmpty) ||
            (product.watt != null && product.watt!.isNotEmpty)) ...[
          Row(
            children: [
              if (product.color != null && product.color!.isNotEmpty)
                _buildDetailChip("Color", product.color!),
              if (product.color != null &&
                  product.color!.isNotEmpty &&
                  product.watt != null &&
                  product.watt!.isNotEmpty)
                const SizedBox(width: 12),
              if (product.watt != null && product.watt!.isNotEmpty)
                _buildDetailChip("Watt", product.watt!),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Text(
          product.description,
          style: GoogleFonts.outfit(
            color: AppColors.softGrey,
            height: 1.5,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {
              if (isInCart) {
                AppRouter.goCart(context);
              } else {
                _addToCart(product);
              }
            },
            icon: Icon(
              isInCart ? Icons.arrow_forward : Icons.shopping_bag,
              color: AppColors.primaryDark,
            ),
            label: Text(
              isInCart ? "GO TO CART" : "ADD TO CART",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(
          const Icon(Icons.star, color: AppColors.accentGold, size: 18),
        );
      } else if (i == fullStars && hasHalfStar) {
        stars.add(
          const Icon(Icons.star_half, color: AppColors.accentGold, size: 18),
        );
      } else {
        stars.add(
          const Icon(Icons.star_border, color: AppColors.accentGold, size: 18),
        );
      }
    }
    return stars;
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.softGrey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.outfit(
              color: AppColors.softGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppColors.textWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
