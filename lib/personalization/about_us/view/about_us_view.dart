import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive_helper.dart';

class HomeAboutSection extends StatelessWidget {
  const HomeAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 40 : 64,
      ),
      child: isMobile
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildLeftPanel()),
        const SizedBox(width: 64),
        Expanded(flex: 4, child: _buildFeatureGrid(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftPanel(),
        const SizedBox(height: 40),
        _buildFeatureGrid(context),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Architectural ',
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: 'Precision\n',
                style: GoogleFonts.outfit(
                  color: AppColors.accentGold,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: 'For Modern Living',
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'At SUN ASSOCIATES, we believe that the soul of a building resides in its details. Our curated selection of electrical hardware and lighting solutions is designed for those who refuse to compromise on quality or aesthetics.',
          style: GoogleFonts.outfit(
            color: AppColors.softGrey,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'From high-velocity designer fans to bespoke chandelier systems, each product in our showroom undergoes rigorous quality testing to ensure durability and unmatched performance.',
          style: GoogleFonts.outfit(
            color: AppColors.softGrey,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            _buildStat('2+', 'Years Excellence'),
            Container(
              width: 1,
              height: 48,
              color: AppColors.borderSoft,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            _buildStat('5k+', 'Satisfied Customers'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.textWhite,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.softGrey,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: 'https://cdn-icons-png.flaticon.com/128/12366/12366737.png',
        title: 'Premium Quality',
        subtitle: 'Only the finest materials and top-tier brands.',
      ),
      _FeatureItem(
        icon: 'https://cdn-icons-png.flaticon.com/128/2731/2731636.png',
        title: 'Energy Efficient',
        subtitle: 'Cutting-edge tech for lower power consumption.',
      ),
      _FeatureItem(
        icon: 'https://cdn-icons-png.flaticon.com/128/11511/11511383.png',
        title: 'Expert Install',
        subtitle: 'Professional guidance and support.',
      ),
      _FeatureItem(
        icon: 'https://cdn-icons-png.flaticon.com/128/8944/8944985.png',
        title: 'Warranty Plus',
        subtitle: 'Extended support for your peace of mind.',
      ),
    ];

    final isMobile = ResponsiveHelper.isMobile(context);
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.0 : 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: features.map((f) => _buildFeatureCard(f)).toList(),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                feature.icon,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported_outlined, size: 20),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                feature.subtitle,
                style: GoogleFonts.outfit(
                  color: AppColors.softGrey,
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
