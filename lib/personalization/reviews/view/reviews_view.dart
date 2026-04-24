import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';

class ReviewsView extends StatelessWidget {
  final String? productId;
  
  const ReviewsView({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Customer Reviews'),
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star_rate,
              color: AppColors.accentGold,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Customer Reviews',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (productId != null)
              Text(
                'Product ID: $productId',
                style: const TextStyle(
                  color: AppColors.softGrey,
                  fontSize: 16,
                ),
              )
            else
              const Text(
                'All Reviews',
                style: TextStyle(
                  color: AppColors.softGrey,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
