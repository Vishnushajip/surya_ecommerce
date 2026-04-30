import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../../data/models/product_model.dart';
import '../view_model/product_details_view_model.dart';
import '../../cart/view_model/cart_view_model.dart';
import '../../cart/widgets/floating_cart_sheet.dart';
import '../../reviews/widgets/review_list_widget.dart';
import '../../home/widgets/product_card.dart';
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

  void _openShareSheet(ProductModel product) {
    final shareUrl = kIsWeb
        ? Uri.base.toString()
        : '${Uri.base.origin}/products/${product.id}';
    final shareText =
        '${product.productName} - ₹${product.price.toStringAsFixed(0)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ShareSheet(
        shareUrl: shareUrl,
        shareText: shareText,
        productName: product.productName,
        onCopied: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Link copied to clipboard',
                style: GoogleFonts.outfit(color: AppColors.primaryDark),
              ),
              backgroundColor: AppColors.accentGold,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
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
              const SizedBox(height: 50),
              _buildSuggestedProductsSection(product),
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
        const SizedBox(height: 40),
        ReviewListWidget(productId: product.id),
        const SizedBox(height: 50),
        _buildSuggestedProductsSection(product),
      ],
    );
  }

  Widget _buildGallerySection(ProductModel product) {
    final imageUrls = product.imageUrls;
    final hasMultiple = imageUrls.length > 1;

    return Column(
      children: [
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScrollConfiguration(
                  behavior: const _DragScrollBehavior(),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: imageUrls.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _openImageViewer(imageUrls, index),
                      child: Center(
                        child: Hero(
                          tag: 'product_image_$index',
                          child: CachedNetworkImageWidget(
                            imageUrl: imageUrls[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _openImageViewer(imageUrls, _currentPage),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (hasMultiple) ...[
                  Positioned(
                    left: 8,
                    child: _buildNavArrow(
                      Icons.chevron_left_rounded,
                      () => _goToPage(_currentPage - 1, imageUrls.length),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: _buildNavArrow(
                      Icons.chevron_right_rounded,
                      () => _goToPage(_currentPage + 1, imageUrls.length),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${imageUrls.length}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasMultiple) ...[
          const SizedBox(height: 15),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: imageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isActive = _currentPage == index;
                return GestureDetector(
                  onTap: () => _goToPage(index, imageUrls.length),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      border: Border.all(
                        color: isActive
                            ? AppColors.accentGold
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImageWidget(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _goToPage(int page, int total) {
    if (page < 0 || page >= total) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  void _openImageViewer(List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) =>
            _ImageViewerScreen(urls: urls, initialIndex: initialIndex),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildInfoSection(ProductModel product, bool isInCart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentGold.withOpacity(0.3),
                ),
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
            if (product.bldc != null && product.bldc!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  product.bldc!,
                  style: GoogleFonts.outfit(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.productName,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildShareButton(product),
          ],
        ),
        const SizedBox(height: 8),
        _buildItemCode(product.id),
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
            if (product.mrp != null && product.mrp! > product.price) ...[
              const SizedBox(width: 12),
              Text(
                "₹ ${product.mrp!.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppColors.softGrey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
        if (product.gst != null && product.gst!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            product.gst!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.softGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  Widget _buildItemCode(String code) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Item code copied',
                style: GoogleFonts.outfit(color: AppColors.primaryDark),
              ),
              backgroundColor: AppColors.accentGold,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ITEM CODE',
              style: GoogleFonts.outfit(
                color: AppColors.softGrey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                code,
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.copy_rounded,
              size: 14,
              color: AppColors.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(ProductModel product) {
    return Material(
      color: AppColors.accentGold.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _openShareSheet(product),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Tooltip(
            message: 'Share',
            child: Icon(
              Icons.share_rounded,
              color: AppColors.accentGold,
              size: 22,
            ),
          ),
        ),
      ),
    );
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

  Widget _buildSuggestedProductsSection(ProductModel currentProduct) {
    final suggestedProductsAsync = ref.watch(
      suggestedProductsProvider(currentProduct.id),
    );

    return suggestedProductsAsync.when(
      data: (page) {
        if (page.items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    'YOU MAY ALSO LIKE',
                    style: GoogleFonts.outfit(
                      color: AppColors.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      context.pushNamed(
                        'all_suggestions',
                        pathParameters: {'id': currentProduct.id},
                      );
                    },
                    child: Text(
                      'SEE ALL',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (page.hasMore)
                    TextButton(
                      onPressed: () => ref
                          .read(
                            suggestedProductsProvider(
                              currentProduct.id,
                            ).notifier,
                          )
                          .loadMore(),
                      child: Text(
                        'LOAD MORE',
                        style: GoogleFonts.outfit(
                          color: AppColors.accentGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: page.items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 160,
                    child: ProductCard(product: page.items[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          'Error loading suggestions: $e',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final String shareUrl;
  final String shareText;
  final String productName;
  final VoidCallback onCopied;

  const _ShareSheet({
    required this.shareUrl,
    required this.shareText,
    required this.productName,
    required this.onCopied,
  });

  String get _encodedUrl => Uri.encodeComponent(shareUrl);
  String get _encodedText => Uri.encodeComponent(shareText);
  String get _encodedTextWithUrl =>
      Uri.encodeComponent('$shareText\n$shareUrl');

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open share target'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    onCopied();
  }

  @override
  Widget build(BuildContext context) {
    final targets = <_ShareTarget>[
      _ShareTarget(
        label: 'WhatsApp',
        icon: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Color(0xFF25D366),
          size: 22,
        ),
        color: const Color(0xFF25D366),
        onTap: () => _open(context, 'https://wa.me/?text=$_encodedTextWithUrl'),
      ),
      _ShareTarget(
        label: 'Telegram',
        icon: const FaIcon(
          FontAwesomeIcons.telegram,
          color: Color(0xFF26A5E4),
          size: 22,
        ),
        color: const Color(0xFF26A5E4),
        onTap: () => _open(
          context,
          'https://t.me/share/url?url=$_encodedUrl&text=$_encodedText',
        ),
      ),
      _ShareTarget(
        label: 'X',
        icon: const FaIcon(
          FontAwesomeIcons.xTwitter,
          color: Color(0xFF000000),
          size: 22,
        ),
        color: const Color(0xFF000000),
        onTap: () => _open(
          context,
          'https://twitter.com/intent/tweet?url=$_encodedUrl&text=$_encodedText',
        ),
      ),
      _ShareTarget(
        label: 'Facebook',
        icon: const FaIcon(
          FontAwesomeIcons.facebook,
          color: Color(0xFF1877F2),
          size: 22,
        ),
        color: const Color(0xFF1877F2),
        onTap: () => _open(
          context,
          'https://www.facebook.com/sharer/sharer.php?u=$_encodedUrl',
        ),
      ),
      _ShareTarget(
        label: 'LinkedIn',
        icon: const FaIcon(
          FontAwesomeIcons.linkedin,
          color: Color(0xFF0A66C2),
          size: 22,
        ),
        color: const Color(0xFF0A66C2),
        onTap: () => _open(
          context,
          'https://www.linkedin.com/sharing/share-offsite/?url=$_encodedUrl',
        ),
      ),
      _ShareTarget(
        label: 'Email',
        icon: const Icon(
          Icons.email_rounded,
          color: Color(0xFFEA4335),
          size: 22,
        ),
        color: const Color(0xFFEA4335),
        onTap: () => _open(
          context,
          'mailto:?subject=${Uri.encodeComponent(productName)}&body=$_encodedTextWithUrl',
        ),
      ),
      _ShareTarget(
        label: 'Copy Link',
        icon: const Icon(
          Icons.link_rounded,
          color: AppColors.accentGold,
          size: 22,
        ),
        color: AppColors.accentGold,
        onTap: () => _copy(context),
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.softGrey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SHARE THIS PRODUCT',
              style: GoogleFonts.outfit(
                color: AppColors.accentGold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: targets
                  .map(
                    (t) =>
                        SizedBox(width: 72, child: _ShareTargetTile(target: t)),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareTarget {
  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareTarget({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ShareTargetTile extends StatelessWidget {
  final _ShareTarget target;
  const _ShareTargetTile({required this.target});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: target.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: target.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: target.color.withValues(alpha: 0.4)),
              ),
              child: Center(child: target.icon),
            ),
            const SizedBox(height: 8),
            Text(
              target.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textWhite,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class _ImageViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _ImageViewerScreen({required this.urls, required this.initialIndex});

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int delta) {
    final next = _currentIndex + delta;
    if (next < 0 || next >= widget.urls.length) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.urls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: const _DragScrollBehavior(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: 'product_image_$index',
                    child: CachedNetworkImageWidget(
                      imageUrl: widget.urls[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (hasMultiple)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.urls.length}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (hasMultiple) ...[
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _goTo(-1),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _goTo(1),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
