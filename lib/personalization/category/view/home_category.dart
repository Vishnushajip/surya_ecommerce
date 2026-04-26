import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/widgets/app_cached_image.dart';

class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.productCount = 0,
  });

  CategoryModel copyWith({int? productCount}) {
    return CategoryModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      productCount: productCount ?? this.productCount,
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['productCategory'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('categories')
      .get();

  final categories = snapshot.docs
      .map((doc) => CategoryModel.fromFirestore(doc))
      .toList();

  final enriched = await Future.wait(
    categories.map((category) async {
      final countSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('productCategory', isEqualTo: category.id)
          .count()
          .get();
      return category.copyWith(productCount: countSnap.count ?? 0);
    }),
  );

  return enriched;
});

class SubCategoryModel {
  final String id;
  final String categoryId;
  final String name;
  final String imageUrl;
  final int productCount;

  SubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    this.productCount = 0,
  });

  SubCategoryModel copyWith({int? productCount}) {
    return SubCategoryModel(
      id: id,
      categoryId: categoryId,
      name: name,
      imageUrl: imageUrl,
      productCount: productCount ?? this.productCount,
    );
  }

  factory SubCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubCategoryModel(
      id: data['id'] ?? doc.id,
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

final subCategoriesProvider = FutureProvider.family<List<SubCategoryModel>, String>((ref, categoryId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('sub_categories')
      .where('categoryId', isEqualTo: categoryId)
      .get();

  final subCategories = snapshot.docs
      .map((doc) => SubCategoryModel.fromFirestore(doc))
      .toList();

  final enriched = await Future.wait(
    subCategories.map((subCategory) async {
      final countSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('subCategoryId', isEqualTo: subCategory.id)
          .count()
          .get();
      return subCategory.copyWith(productCount: countSnap.count ?? 0);
    }),
  );

  return enriched;
});

class ShopByCategoryWidget extends ConsumerWidget {
  const ShopByCategoryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    return categoriesAsync.when(
      data: (categories) =>
          _CategorySection(categories: categories, isMobile: isMobile),
      loading: () => const SizedBox(
        height: 500,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final List<CategoryModel> categories;
  final bool isMobile;

  const _CategorySection({required this.categories, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final displayedCategories = (List<CategoryModel>.from(
      categories,
    )..shuffle()).take(5).toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(isMobile: isMobile),
          const SizedBox(height: 36),
          _StaggeredCategoryGrid(
            categories: displayedCategories,
            isMobile: isMobile,
          ),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => context.push('/categories'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VIEW ALL CATEGORIES',
                    style: GoogleFonts.outfit(
                      color: AppColors.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.accentGold,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool isMobile;
  const _SectionHeader({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COLLECTIONS',
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Shop By Category',
          style: GoogleFonts.outfit(
            color: AppColors.textWhite,
            fontSize: isMobile ? 26 : 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _StaggeredCategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final bool isMobile;

  const _StaggeredCategoryGrid({
    required this.categories,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: categories.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return _CategoryCard(
            category: categories[index],
            height: index.isEven ? 200 : 260,
          );
        },
      );
    }

    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: _CategoryCard(category: categories[0]),
        ),
        if (categories.length > 1)
          StaggeredGridTile.count(
            crossAxisCellCount: 2,
            mainAxisCellCount: 1,
            child: _CategoryCard(category: categories[1]),
          ),
        if (categories.length > 2)
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: _CategoryCard(category: categories[2]),
          ),
        if (categories.length > 3)
          StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: _CategoryCard(category: categories[3]),
          ),
        if (categories.length > 4)
          StaggeredGridTile.count(
            crossAxisCellCount: 4,
            mainAxisCellCount: 1.5,
            child: _CategoryCard(category: categories[4]),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final double? height;

  const _CategoryCard({required this.category, this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'sub_categories',
          pathParameters: {'id': category.id},
          queryParameters: {'name': category.name},
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.cardDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppCachedImage(url: category.imageUrl, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: AppColors.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${category.productCount} ITEMS',
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryDark,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
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
