import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/personalization/reviews/widgets/review_list_widget.dart';

class HomeTestimonialsSection extends StatelessWidget {
  const HomeTestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        image: DecorationImage(
          image: const NetworkImage(
            'https://images.pexels.com/photos/9821386/pexels-photo-9821386.jpeg',
          ),
          opacity: 0.03,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Column(
        children: [
          Text(
            "TESTIMONIALS",
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "What Our Customers Say",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 50),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const ReviewListWidget(
              productId: 'overall_experience',
              isTestimonial: true,
            ),
          ),
        ],
      ),
    );
  }
}
