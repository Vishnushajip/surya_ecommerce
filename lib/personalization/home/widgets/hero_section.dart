import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../routes/app_router.dart';

class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return SizedBox(
      width: double.infinity,
      height: isMobile ? 420 : 540,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: const AppCachedImage(
              url:
                  'https://www.luxurybathroomsandtiles.co.uk/cdn/shop/files/Bathroom_suite_with_brushed_brass_fittings_872x700.jpg?v=1707427492',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Color(0xCC0a0a0a),
                  Color(0xFF0a0a0a),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMobile ? 24 : 64,
              right: isMobile ? 24 : 64,
              top: isMobile ? 100 : 140,
              bottom: isMobile ? 32 : 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSFORMING SPACES WITH ELEGANCE',
                  style: GoogleFonts.outfit(
                    color: AppColors.accentGold,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  AppConstants.companyName,
                  style: GoogleFonts.outfit(
                    color: AppColors.textWhite,
                    fontSize: isMobile ? 38 : 68,
                    fontWeight: FontWeight.w900,
                    letterSpacing: isMobile ? 1 : 2,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                SizedBox(
                  width: isMobile ? double.infinity : 480,
                  child: Text(
                    'The ultimate destination for premium architectural hardware, luxury fans, and sophisticated electrical solutions. Elevate your living spaces with precision engineering and golden aesthetics.',
                    style: GoogleFonts.outfit(
                      color: AppColors.textWhite.withValues(alpha: 0.55),
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 32),
                ElevatedButton(
                  onPressed: () => AppRouter.goProducts(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 28,
                      vertical: isMobile ? 13 : 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'EXPLORE COLLECTIONS',
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
