import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'core/theme/app_colors.dart';
import 'core/services/firebase_service.dart';
import 'core/constants/app_constants.dart';
import 'core/widgets/splash_gate.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/review_repository.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  await FirebaseService.instance.initialize();

  final prefs = await SharedPreferences.getInstance();

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return MaterialApp(
      home: Scaffold(
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
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'We apologize for the inconvenience. Please refresh the page or try again later.',
                  style: TextStyle(color: AppColors.softGrey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (AppConstants.enableDebugMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${errorDetails.toString()}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    ProviderScope(
      overrides: [
        cartRepositoryProvider.overrideWithValue(CartRepository(prefs)),
        productRepositoryProvider.overrideWithValue(
          ProductRepository(FirebaseService.instance),
        ),
        reviewRepositoryProvider.overrideWithValue(
          ReviewRepository(FirebaseService.instance),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  throw UnimplementedError('CartRepository must be overridden in main.dart');
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  throw UnimplementedError('ProductRepository must be overridden in main.dart');
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  throw UnimplementedError('ReviewRepository must be overridden in main.dart');
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: AppConstants.enableDebugMode,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        if (kIsWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            html.window.dispatchEvent(html.Event('flutter-first-frame'));
          });
        }
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: SplashGate(child: child!),
        );
      },
    );
  }
}
