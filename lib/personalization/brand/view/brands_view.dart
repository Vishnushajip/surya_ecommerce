import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/personalization/brand/view/home_brand.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import 'brand_products_view.dart';

class BrandsView extends ConsumerWidget {
  const BrandsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'OUR BRANDS'),
      backgroundColor: AppColors.primaryDark,
      body: brandsAsync.when(
        data: (brands) {
          if (brands.isEmpty) {
            return const Center(child: Text('No brands found', style: TextStyle(color: Colors.white)));
          }
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 80,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRUSTED BRANDS',
                  style: GoogleFonts.outfit(
                    color: AppColors.accentGold,
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(width: 60, height: 4, color: AppColors.accentGold),
                const SizedBox(height: 32),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1,
                  ),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    return _BrandCard(brand: brand);
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final BrandModel brand;
  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: brand.imageUrl.isNotEmpty
                    ? Image.network(
                        brand.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.business, color: AppColors.accentGold, size: 40),
                      )
                    : const Icon(Icons.business, color: AppColors.accentGold, size: 40),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: Text(
                  brand.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
