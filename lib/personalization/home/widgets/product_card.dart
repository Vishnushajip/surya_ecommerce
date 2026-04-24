import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/core/responsive/responsive_helper.dart';
import 'package:surya_ecommerce/core/widgets/app_cached_image.dart';
import 'package:surya_ecommerce/data/models/product_model.dart';
import 'package:surya_ecommerce/routes/app_router.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isNew = _isNewArrival(product);

    return GestureDetector(
      onTap: () => AppRouter.goProductDetails(context, product.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderSoft.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: isMobile ? 120 : 150,
                  width: double.infinity,
                  child: AppCachedImage(
                    url: product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : null,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.outfit(
                          color: AppColors.primaryDark,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: GoogleFonts.outfit(
                      color: AppColors.textWhite,
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildStars(product.ratingAverage),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: AppColors.accentGold,
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.accentGold,
                        size: 14,
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

  bool _isNewArrival(ProductModel product) {
    final createdDate = product.createdDate.toDate();
    return DateTime.now().difference(createdDate).inDays <= 7;
  }

  Widget _buildStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(
          const Icon(Icons.star, color: AppColors.accentGold, size: 10),
        );
      } else if (i == fullStars && hasHalfStar) {
        stars.add(
          const Icon(Icons.star_half, color: AppColors.accentGold, size: 10),
        );
      } else {
        stars.add(
          const Icon(Icons.star_border, color: AppColors.accentGold, size: 10),
        );
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
