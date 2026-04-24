import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../view_model/cart_view_model.dart';
import '../../../routes/app_router.dart';

// Local provider to handle the visibility state of the floating bar
final isCartHiddenProvider = StateProvider<bool>((ref) => false);

class FloatingCartSheet extends ConsumerWidget {
  const FloatingCartSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartViewModelProvider);
    final isHidden = ref.watch(isCartHiddenProvider);
    final currentPath = ModalRoute.of(context)?.settings.name;

    if (currentPath == '/cart' || currentPath == '/checkout') {
      return const SizedBox.shrink();
    }

    return cartAsync.when(
      data: (summary) {
        if (summary.totalItems == 0) return const SizedBox.shrink();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isHidden
                  ? _buildUnhideButton(ref)
                  : _buildFullCartBar(context, ref, summary),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildUnhideButton(WidgetRef ref) {
    return Align(
      alignment: Alignment.bottomRight,
      child: FloatingActionButton.small(
        backgroundColor: AppColors.accentGold,
        onPressed: () => ref.read(isCartHiddenProvider.notifier).state = false,
        child: const Icon(Icons.shopping_cart, color: AppColors.primaryDark),
      ),
    );
  }

  Widget _buildFullCartBar(
    BuildContext context,
    WidgetRef ref,
    dynamic summary,
  ) {
    return Container(
      key: const ValueKey('expanded_cart'),
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Close/Hide Button
          IconButton(
            onPressed: () =>
                ref.read(isCartHiddenProvider.notifier).state = true,
            icon: const Icon(Icons.close, color: AppColors.softGrey, size: 20),
          ),

          // Icon with Badge
          GestureDetector(
            onTap: () => AppRouter.goCart(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.accentGold,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${summary.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Item Info
          Expanded(
            child: GestureDetector(
              onTap: () => AppRouter.goCart(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${summary.totalItems} ${summary.totalItems == 1 ? 'item' : 'items'}',
                    style: GoogleFonts.outfit(
                      color: AppColors.softGrey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    summary.formattedGrandTotal,
                    style: GoogleFonts.outfit(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () => AppRouter.goCart(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(
              'VIEW CART',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
