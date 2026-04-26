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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark.withOpacity(0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _toolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // ── Leading: back or logo ──
                if (showBackButton)
                  _AppBarIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                  )
                else
                  _AppBarIconButton(
                    iconWidget: Image.network(
                      'assets/images/logo_bg_removed.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    onTap: () => _NavBottomSheet.show(context),
                  ),

                const SizedBox(width: 6),

                // ── Brand title ──
                Expanded(
                  child: Text(
                    'SUN ASSOCIATES',
                    style: GoogleFonts.bebasNeue(
                      color: AppColors.accentGold,
                      fontSize: isWide ? 26 : 21,
                      letterSpacing: 1.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ── Search icon ──
                if (showSearch) ...[
                  _AppBarIconButton(
                    iconWidget: Image.network(
                      'https://cdn-icons-png.flaticon.com/128/751/751463.png',
                      width: 20,
                      height: 20,
                      color: AppColors.textWhite,
                    ),
                    onTap: () => context.go('/products'),
                  ),
                  _AppBarDivider(),
                ],

                // ── Menu icon ──
                _AppBarIconButton(
                  iconWidget: const Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: AppColors.accentGold,
                  ),
                  onTap: () => _NavBottomSheet.show(context),
                ),

                _AppBarDivider(),

                // ── Cart icon ──
                _CartButton(itemCount: cartItemCount, context: context),

                if (actions != null) ...actions!,

                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);
}

// ─────────────────────────── Atoms ───────────────────────────

class _AppBarIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;

  const _AppBarIconButton({this.icon, this.iconWidget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.accentGold.withOpacity(0.12),
        highlightColor: AppColors.accentGold.withOpacity(0.06),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child:
                iconWidget ?? Icon(icon, color: AppColors.textWhite, size: 20),
          ),
        ),
      ),
    );
  }
}

class _AppBarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: AppColors.borderSoft,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

// ─────────────────────────── Cart ───────────────────────────

class _CartButton extends StatelessWidget {
  final int itemCount;
  final BuildContext context;
  const _CartButton({required this.itemCount, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _AppBarIconButton(
          iconWidget: Image.network(
            'https://cdn-icons-png.flaticon.com/128/5337/5337564.png',
            width: 22,
            height: 22,
            color: AppColors.textWhite,
          ),
          onTap: () => AppRouter.goCart(ctx),
        ),
        if (itemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryDark, width: 1.5),
                ),
                child: Text(
                  itemCount > 99 ? '99+' : '$itemCount',
                  style: GoogleFonts.dmSans(
                    color: AppColors.primaryDark,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────── Nav Bottom Sheet ───────────────────────────

class _NavBottomSheet extends StatelessWidget {
  final BuildContext context;
  const _NavBottomSheet({required this.context});

  static void show(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.borderSoft, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'NAVIGATION',
              style: GoogleFonts.syne(
                color: AppColors.softGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 6),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accentGold.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSoft, width: 0.5),
                ),
                child: Icon(icon, color: AppColors.accentGold, size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.borderSoft,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
