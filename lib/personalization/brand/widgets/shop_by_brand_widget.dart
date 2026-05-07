import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:surya_ecommerce/personalization/brand/view/home_brand.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../view/brand_products_view.dart';

class ShopByBrandWidget extends ConsumerWidget {
  const ShopByBrandWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 80,
        vertical: 40,
      ),
      color: AppColors.secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHOP BY BRAND',
                    style: GoogleFonts.outfit(
                      color: AppColors.textWhite,
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 40, height: 3, color: AppColors.accentGold),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all brands
                  context.go('/brands');
                },
                child: Row(
                  children: [
                    Text(
                      'VIEW ALL',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.accentGold),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          brandsAsync.when(
            data: (brands) {
              if (brands.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrandProductsView(brand: brand),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSoft.withOpacity(0.2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (brand.imageUrl.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Image.network(brand.imageUrl, fit: BoxFit.contain),
                                ),
                              )
                            else
                              const Icon(Icons.business, color: AppColors.accentGold, size: 32),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
                              child: Text(
                                brand.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: AppColors.textWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
            error: (e, _) => Text('Error loading brands', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
