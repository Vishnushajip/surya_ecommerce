import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../responsive/responsive_helper.dart';
import '../../routes/app_router.dart';
import '../../personalization/cart/view_model/cart_view_model.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showSearch;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showSearch = true,
    this.actions,
    this.onBackPressed,
  });

  static const double _toolbarHeight = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemCount = ref
        .watch(cartViewModelProvider)
        .maybeWhen(data: (cart) => cart.totalItems, orElse: () => 0);

    final isWide =
        ResponsiveHelper.isDesktop(context) ||
        ResponsiveHelper.isTablet(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 0.5),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: _toolbarHeight,
        titleSpacing: 0,
        title: _Logo(compact: !isWide),
        leading: showBackButton
            ? _IconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              )
            : _IconBtn(
                iconWidget: Image.network(
                  'https://cdn-icons-png.flaticon.com/128/3801/3801845.png',
                  width: 18,
                  height: 18,
                  color: AppColors.textWhite,
                ),
                onTap: () => _NavBottomSheet.show(context),
              ),
        actions: [
          if (isWide) ...[
            _NavMenuButton(context: context),
            _VerticalDivider(),
            if (showSearch) _SearchPill(context: context),
          ] else if (showSearch)
            _IconBtn(
              iconWidget: Image.network(
                'https://cdn-icons-png.flaticon.com/128/751/751463.png',
                width: 18,
                height: 18,
                color: AppColors.textWhite,
              ),
              onTap: () => context.go('/products'),
            ),
          _CartButton(itemCount: cartItemCount, context: context),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);
}

class _Logo extends StatelessWidget {
  final bool compact;
  const _Logo({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Text(
      "SUN ASSOCIATES",
      style: GoogleFonts.bebasNeue(
        color: AppColors.accentGold,
        fontSize: compact ? 22 : 28,
        letterSpacing: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;

  const _IconBtn({this.icon, this.iconWidget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: iconWidget ?? Icon(icon, color: AppColors.textWhite, size: 20),
      onPressed: onTap,
      splashRadius: 20,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: AppColors.borderSoft,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final BuildContext context;
  const _SearchPill({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.go('/products'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'https://cdn-icons-png.flaticon.com/128/751/751463.png',
              width: 14,
              height: 14,
              color: AppColors.softGrey,
            ),
            const SizedBox(width: 6),
            Text(
              'Search',
              style: GoogleFonts.dmSans(
                color: AppColors.softGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int itemCount;
  final BuildContext context;
  const _CartButton({required this.itemCount, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Image.network(
            'https://cdn-icons-png.flaticon.com/128/5337/5337564.png',
            width: 22,
            height: 22,
            color: AppColors.textWhite,
          ),
          onPressed: () => AppRouter.goCart(ctx),
          tooltip: 'Cart',
          splashRadius: 20,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        if (itemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.accentGold,
                shape: BoxShape.circle,
              ),
              child: Text(
                itemCount > 99 ? '99+' : '$itemCount',
                style: GoogleFonts.dmSans(
                  color: AppColors.primaryDark,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _NavMenuButton extends StatelessWidget {
  final BuildContext context;
  const _NavMenuButton({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return TextButton.icon(
      onPressed: () => _NavBottomSheet.show(ctx),
      icon: const Icon(
        Icons.grid_view_rounded,
        size: 15,
        color: AppColors.accentGold,
      ),
      label: Text(
        'Menu',
        style: GoogleFonts.syne(
          color: AppColors.accentGold,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NavBottomSheet extends StatelessWidget {
  final BuildContext context;
  const _NavBottomSheet({required this.context});

  static void show(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NavBottomSheet(context: ctx),
    );
  }

  static const _navItems = [
    (icon: Icons.home_rounded, label: 'Home', route: '/'),
    (icon: Icons.info_outline_rounded, label: 'About', route: '/about'),
    (icon: Icons.inventory_2_outlined, label: 'Products', route: '/products'),
    (icon: Icons.mail_outline_rounded, label: 'Contact', route: '/contact'),
  ];

  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'NAVIGATION',
            style: GoogleFonts.syne(
              color: AppColors.softGrey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ..._navItems.map(
            (item) => _NavTile(
              icon: item.icon,
              label: item.label,
              onTap: () {
                Navigator.pop(ctx);
                ctx.go(item.route);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accentGold, size: 17),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.borderSoft,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}
