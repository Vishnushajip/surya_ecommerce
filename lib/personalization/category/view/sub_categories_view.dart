import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/core/responsive/responsive_helper.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import 'package:surya_ecommerce/personalization/category/view/home_category.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final activeFilterProvider = StateProvider<String>((ref) => 'All');
final sortOrderProvider = StateProvider<String>((ref) => 'Default');

const List<String> _sortOptions = ['Default', 'A → Z', 'Z → A', 'Most Items', 'Fewest Items'];

class SubCategoriesView extends ConsumerWidget {
  final String categoryId;
  final String categoryName;

  const SubCategoriesView({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCategoriesAsync = ref.watch(subCategoriesProvider(categoryId));
    final isMobile = ResponsiveHelper.isMobile(context);
    final searchQuery = ref.watch(searchQueryProvider);
    final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: categoryName.toUpperCase()),
      body: subCategoriesAsync.when(
        data: (subCategories) {
          var filtered = subCategories.where((s) {
            return s.name.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          if (sortOrder == 'A → Z') {
            filtered.sort((a, b) => a.name.compareTo(b.name));
          } else if (sortOrder == 'Z → A') {
            filtered.sort((a, b) => b.name.compareTo(a.name));
          } else if (sortOrder == 'Most Items') {
            filtered.sort((a, b) => b.productCount.compareTo(a.productCount));
          } else if (sortOrder == 'Fewest Items') {
            filtered.sort((a, b) => a.productCount.compareTo(b.productCount));
          }

          return Column(
            children: [
              _SearchAndSortBar(isMobile: isMobile),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 64,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} sub-categories',
                      style: GoogleFonts.outfit(
                        color: AppColors.softGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              color: AppColors.softGrey.withOpacity(0.5),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sub-categories found',
                              style: GoogleFonts.outfit(color: AppColors.textWhite),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 64,
                          vertical: 8,
                        ),
                        child: MasonryGridView.count(
                          crossAxisCount: isMobile ? 2 : 4,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          itemCount: filtered.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final subCategory = filtered[index];
                            return _SubCategoryCard(
                              subCategory: subCategory,
                              categoryId: categoryId,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class _SearchAndSortBar extends ConsumerWidget {
  final bool isMobile;

  const _SearchAndSortBar({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 64, 16, isMobile ? 16 : 64, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSoft.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (val) =>
                    ref.read(searchQueryProvider.notifier).state = val,
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search sub-categories...',
                  hintStyle: GoogleFonts.outfit(
                    color: AppColors.softGrey.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.softGrey.withOpacity(0.5),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SortDropdown(),
        ],
      ),
    );
  }
}

class _SortDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOrder = ref.watch(sortOrderProvider);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sortOrder,
          dropdownColor: AppColors.cardDark,
          icon: Icon(Icons.unfold_more_rounded, color: AppColors.softGrey, size: 18),
          items: _sortOptions.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(
                s,
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) ref.read(sortOrderProvider.notifier).state = val;
          },
        ),
      ),
    );
  }
}


class _SubCategoryCard extends ConsumerWidget {
  final dynamic subCategory;
  final String categoryId;

  const _SubCategoryCard({
    required this.subCategory,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'category_products',
          pathParameters: {'id': categoryId},
          queryParameters: {
            'subId': subCategory.id,
            'subName': subCategory.name,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.cardDark,
          border: Border.all(color: AppColors.borderSoft.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: AppColors.borderSoft.withOpacity(0.08),
                    child: subCategory.imageUrl.isNotEmpty
                        ? Image.network(
                            subCategory.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.category, color: AppColors.accentGold),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.category, color: AppColors.accentGold),
                          ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subCategory.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: AppColors.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subCategory.productCount} ITEMS',
                    style: GoogleFonts.outfit(
                      color: AppColors.accentGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}