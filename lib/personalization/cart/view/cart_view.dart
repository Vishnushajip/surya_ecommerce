import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/cart_model.dart';
import '../view_model/cart_view_model.dart';
import '../../../routes/app_router.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          AppStrings.shoppingCart.toUpperCase(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.softGrey),
            onPressed: () => _showClearCartDialog(context, ref),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (error, stack) => _buildErrorState(context, error),
        data: (cartSummary) {
          if (cartSummary.isEmpty) return _buildEmptyState(context);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cartSummary.items.length,
                  itemBuilder: (context, index) =>
                      _buildCartItem(context, ref, cartSummary.items[index]),
                ),
              ),
              _buildCheckoutSection(context, cartSummary),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.accentGold.withOpacity(0.2),
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.cartIsEmpty,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your high-end collection awaits.',
            style: GoogleFonts.outfit(color: AppColors.softGrey, fontSize: 16),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () => AppRouter.goProducts(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                "SHOP NOW",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    CartModel cartItem,
  ) {
    final cartNotifier = ref.read(cartViewModelProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImageWidget(
                imageUrl: cartItem.product.imageUrls.first,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cartItem.product.productName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showDeleteDialog(context, ref, cartItem),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.softGrey,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    cartItem.product.productCategory,
                    style: GoogleFonts.outfit(
                      color: AppColors.softGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cartItem.formattedItemPrice,
                        style: GoogleFonts.outfit(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondaryDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _qtyBtn(Icons.remove, () {
                              if (cartItem.quantity > 1) {
                                cartNotifier.updateQuantity(
                                  cartItem.id,
                                  cartItem.quantity - 1,
                                );
                              }
                            }),
                            Text(
                              '${cartItem.quantity}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _qtyBtn(
                              Icons.add,
                              () => cartNotifier.updateQuantity(
                                cartItem.id,
                                cartItem.quantity + 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Icon(icon, color: AppColors.accentGold, size: 16),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, dynamic cartSummary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Subtotal",
                  style: GoogleFonts.outfit(color: AppColors.softGrey),
                ),
                Text(
                  cartSummary.formattedGrandTotal,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => AppRouter.goCheckout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "PROCEED TO CHECKOUT",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialogs remained largely the same but styled for Dark Theme
  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    CartModel cartItem,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Remove Item',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'Remove ${cartItem.product.productName}?',
          style: GoogleFonts.outfit(color: AppColors.softGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(cartViewModelProvider.notifier)
                  .removeFromCart(cartItem.id);
              Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.outfit(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Clear Cart',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'Discard all items?',
          style: GoogleFonts.outfit(color: AppColors.softGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartViewModelProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.outfit(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
    );
  }
}
