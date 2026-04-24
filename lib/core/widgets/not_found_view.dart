import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../../routes/app_router.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Page Not Found'),
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                '404',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The page you are looking for does not exist or has been moved.',
                style: TextStyle(
                  color: AppColors.softGrey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => AppRouter.goHome(context),
                child: const Text('Go Home'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => AppRouter.goProducts(context),
                child: const Text('Browse Products'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
