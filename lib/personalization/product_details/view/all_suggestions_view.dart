import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../home/widgets/product_card.dart';
import '../view_model/product_details_view_model.dart';

class AllSuggestionsView extends ConsumerWidget {
  final String productId;

  const AllSuggestionsView({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedProductsAsync = ref.watch(suggestedProductsProvider(productId));
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(title: 'SUGGESTED FOR YOU'),
      body: suggestedProductsAsync.when(
        data: (page) {
          if (page.items.isEmpty) {
            return Center(
              child: Text(
                'No suggestions found.',
                style: GoogleFonts.outfit(color: AppColors.softGrey),
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                ref.read(suggestedProductsProvider(productId).notifier).loadMore();
              }
              return true;
            },
            child: GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 64,
                vertical: 24,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : 4,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: page.items.length + (page.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < page.items.length) {
                  return ProductCard(product: page.items[index]);
                } else {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accentGold),
                  );
                }
              },
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'Error loading suggestions: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
