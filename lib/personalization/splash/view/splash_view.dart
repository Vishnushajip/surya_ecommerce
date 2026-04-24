import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:surya_ecommerce/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.3, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFF0D3035),
              AppColors.primaryDark,
              Color(0xFF010F11),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SUN ASSOCIATES',
                    style: GoogleFonts.outfit(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentGold,
                      letterSpacing: 12,
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: size.width * 0.45,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.accentGold.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'ARCHITECTURAL EXCELLENCE',
                    style: GoogleFonts.raleway(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: AppColors.softGrey.withOpacity(0.6),
                      letterSpacing: 4.5,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: size.height * 0.1,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentGold.withOpacity(0.85),
                    ),
                    backgroundColor: AppColors.borderSoft,
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
