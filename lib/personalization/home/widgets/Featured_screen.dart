import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/data/models/product_model.dart';
import 'package:surya_ecommerce/main.dart';
import 'package:surya_ecommerce/routes/app_router.dart';
import 'package:surya_ecommerce/core/responsive/responsive_helper.dart';
import 'product_card.dart';

final featuredProductsProvider = FutureProvider<List<ProductModel>>((
  ref,
) async {
  final repository = ref.watch(productRepositoryProvider);
  try {
    final featured = await repository.getFeaturedProducts(limit: 100);
    if (featured.isNotEmpty) return featured;

    return await repository.getProducts(limit: 100, descending: true);
  } catch (e) {
    return [];
  }
});

class FeaturedSection extends ConsumerWidget {
  const FeaturedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(featuredProductsProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 48,
        horizontal: isMobile ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURATED SELECTION',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentGold,
                        fontSize: isMobile ? 9 : 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Featured Arrivals',
                      style: GoogleFonts.outfit(
                        color: AppColors.textWhite,
                        fontSize: isMobile ? 26 : 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!isMobile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextButton(
                    onPressed: () => AppRouter.goProducts(context),
                    child: Row(
                      children: [
                        Text(
                          'EXPLORE ALL',
                          style: GoogleFonts.outfit(
                            color: AppColors.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.accentGold,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: const Center(
                      child: Text(
                        'No featured products found',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: isMobile ? 210 : 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final horizontalPadding = isMobile ? 0 : 120;
                    final availableWidth = screenWidth - horizontalPadding;
                    final itemWidth = isMobile
                        ? (availableWidth / 2.2)
                        : (availableWidth / 6.2);

                    return Container(
                      width: itemWidth,
                      margin: const EdgeInsets.only(right: 16),
                      child: ProductCard(product: products[index]),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
          ),
          if (isMobile) ...[
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => AppRouter.goProducts(context),
                child: Text(
                  'EXPLORE ALL PRODUCTS',
                  style: GoogleFonts.outfit(
                    color: AppColors.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
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
