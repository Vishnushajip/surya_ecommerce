import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../personalization/home/view/home_view.dart';
import '../personalization/about_us/view/about_us_view.dart';
import '../personalization/all_products/view/all_products_view.dart';
import '../personalization/product_details/view/product_details_view.dart';
import '../personalization/cart/view/cart_view.dart';
import '../personalization/checkout/view/checkout_view.dart';
import '../personalization/contact_us/view/contact_us_view.dart';
import '../personalization/reviews/view/reviews_view.dart';
import '../personalization/category/view/category_products_view.dart';
import '../personalization/category/view/all_categories_view.dart';
import '../personalization/category/view/home_category.dart';
import '../core/widgets/not_found_view.dart';

import '../personalization/cart/widgets/floating_cart_sheet.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: AppConstants.enableDebugMode,
    errorBuilder: (context, state) => const NotFoundView(),
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final bool isCartOrCheckout =
              state.uri.path == '/cart' || state.uri.path == '/checkout';
          return Scaffold(
            body: Stack(
              children: [
                RepaintBoundary(child: child),
                if (!isCartOrCheckout)
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FloatingCartSheet(),
                  ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) =>
                const MaterialPage(key: ValueKey('home'), child: HomeView()),
          ),

          GoRoute(
            path: '/about',
            name: 'about',
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('about'),
              child: HomeAboutSection(),
            ),
          ),

          GoRoute(
            path: '/products',
            name: 'products',
            pageBuilder: (context, state) {
              final category = state.uri.queryParameters['category'];
              final search = state.uri.queryParameters['search'];
              return MaterialPage(
                key: ValueKey('products_${category ?? ''}_${search ?? ''}'),
                child: AllProductsView(),
              );
            },
          ),

          GoRoute(
            path: '/products/:id',
            name: 'product_details',
            pageBuilder: (context, state) {
              final productId = state.pathParameters['id']!;
              return MaterialPage(
                key: ValueKey('product_$productId'),
                child: ProductDetailsView(productId: productId),
              );
            },
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            pageBuilder: (context, state) =>
                const MaterialPage(key: ValueKey('cart'), child: CartView()),
          ),

          GoRoute(
            path: '/checkout',
            name: 'checkout',
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('checkout'),
              child: CheckoutView(),
            ),
          ),

          GoRoute(
            path: '/contact',
            name: 'contact',
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('contact'),
              child: ContactUsView(),
            ),
          ),

          GoRoute(
            path: '/reviews',
            name: 'reviews',
            pageBuilder: (context, state) {
              final productId = state.uri.queryParameters['productId'];
              return MaterialPage(
                key: ValueKey('reviews_$productId'),
                child: ReviewsView(productId: productId),
              );
            },
          ),
          GoRoute(
            path: '/category/:id',
            name: 'category_products',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(
                key: ValueKey('category_$id'),
                child: CategoryProductsView(
                  category: CategoryModel(id: id, name: '', imageUrl: ''),
                ),
              );
            },
          ),
          GoRoute(
            path: '/categories',
            name: 'all_categories',
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('all_categories'),
              child: AllCategoriesView(),
            ),
          ),
        ],
      ),
    ],
  );

  static void goHome(BuildContext context) {
    context.go('/');
  }

  static void goAbout(BuildContext context) {
    context.go('/about');
  }

  static void goProducts(
    BuildContext context, {
    String? category,
    String? search,
  }) {
    final queryParameters = <String, String>{};
    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final uri = Uri(path: '/products', queryParameters: queryParameters);
    context.go(uri.toString());
  }

  static void goProductDetails(BuildContext context, String productId) {
    context.go('/products/$productId');
  }

  static void goCart(BuildContext context) {
    context.push('/cart');
  }

  static void goCheckout(BuildContext context) {
    context.go('/checkout');
  }

  static void goContact(BuildContext context) {
    context.go('/contact');
  }

  static void goReviews(BuildContext context, {String? productId}) {
    final queryParameters = <String, String>{};
    if (productId != null && productId.isNotEmpty) {
      queryParameters['productId'] = productId;
    }

    final uri = Uri(path: '/reviews', queryParameters: queryParameters);
    context.go(uri.toString());
  }

  static void pushProductDetails(BuildContext context, String productId) {
    context.push('/products/$productId');
  }

  static void pushCheckout(BuildContext context) {
    context.push('/checkout');
  }

  static void pushReviews(BuildContext context, {String? productId}) {
    final queryParameters = <String, String>{};
    if (productId != null && productId.isNotEmpty) {
      queryParameters['productId'] = productId;
    }

    final uri = Uri(path: '/reviews', queryParameters: queryParameters);
    context.push(uri.toString());
  }

  static void pop(BuildContext context) {
    context.pop();
  }

  static bool canPop(BuildContext context) {
    return context.canPop();
  }

  static String getCurrentRouteName(BuildContext context) {
    final route = GoRouterState.of(context);
    return route.name ?? 'unknown';
  }

  static String getCurrentPath(BuildContext context) {
    final route = GoRouterState.of(context);
    return route.uri.toString();
  }

  static bool isRouteActive(BuildContext context, String routeName) {
    return getCurrentRouteName(context) == routeName;
  }

  static Map<String, String> getMetaDataForRoute(String routeName) {
    switch (routeName) {
      case 'home':
        return {
          'title': AppConstants.defaultTitle,
          'description': AppConstants.defaultDescription,
          'keywords': AppConstants.defaultKeywords,
        };
      case 'about':
        return {
          'title': 'About SUN Associates - Our Story & Legacy',
          'description':
              'Learn about SUN Associates, your trusted electrical and hardware partner since 1995. Discover our commitment to quality and customer satisfaction.',
          'keywords':
              'about SUN associates, company history, electrical hardware mumbai',
        };
      case 'products':
        return {
          'title': 'Products - SUN Associates Electrical & Hardware',
          'description':
              'Browse our extensive collection of premium electrical and hardware products. Quality switches, fans, lighting, tools, and more.',
          'keywords':
              'electrical products, hardware products, switches, fans, lighting, tools',
        };
      case 'contact':
        return {
          'title': 'Contact SUN Associates - Get in Touch',
          'description':
              'Contact SUN Associates for all your electrical and hardware needs. Visit our store in Mumbai or call us for expert assistance.',
          'keywords':
              'contact SUN associates, electrical hardware mumbai contact, store address',
        };
      default:
        return {
          'title': AppConstants.defaultTitle,
          'description': AppConstants.defaultDescription,
          'keywords': AppConstants.defaultKeywords,
        };
    }
  }

  // Route guards (for future authentication)
  static Future<bool> canAccessRoute(String routeName) async {
    // For now, all routes are public
    // In the future, add authentication logic here
    return true;
  }

  // Custom transition builders
  static CustomTransitionPage buildTransitionPage({
    required LocalKey key,
    required Widget child,
    required String transitionType,
  }) {
    switch (transitionType) {
      case 'fade':
        return CustomTransitionPage(
          key: key,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      case 'slide':
        return CustomTransitionPage(
          key: key,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      default:
        return CustomTransitionPage(
          key: key,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
    }
  }
}

// Route configuration for web SEO
class RouteConfig {
  static const Map<String, RouteInfo> routes = {
    '/': RouteInfo(
      path: '/',
      name: 'home',
      title: AppConstants.defaultTitle,
      description: AppConstants.defaultDescription,
      keywords: AppConstants.defaultKeywords,
    ),
    '/about': RouteInfo(
      path: '/about',
      name: 'about',
      title: 'About SUN Associates - Our Story & Legacy',
      description:
          'Learn about SUN Associates, your trusted electrical and hardware partner since 1995.',
      keywords:
          'about SUN associates, company history, electrical hardware mumbai',
    ),
    '/products': RouteInfo(
      path: '/products',
      name: 'products',
      title: 'Products - SUN Associates Electrical & Hardware',
      description:
          'Browse our extensive collection of premium electrical and hardware products.',
      keywords:
          'electrical products, hardware products, switches, fans, lighting, tools',
    ),
    '/contact': RouteInfo(
      path: '/contact',
      name: 'contact',
      title: 'Contact SUN Associates - Get in Touch',
      description:
          'Contact SUN ASSOCIATES for all your electrical and hardware needs.',
      keywords: 'contact SUN associates, electrical hardware mumbai contact',
    ),
  };
}

class RouteInfo {
  final String path;
  final String name;
  final String title;
  final String description;
  final String keywords;

  const RouteInfo({
    required this.path,
    required this.name,
    required this.title,
    required this.description,
    required this.keywords,
  });
}
