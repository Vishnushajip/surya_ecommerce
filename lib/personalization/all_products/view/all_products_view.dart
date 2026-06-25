import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/core/widgets/app_cached_image.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import 'package:surya_ecommerce/core/widgets/filter_dropdown_field.dart';
import 'package:surya_ecommerce/data/models/product_model.dart';
import 'package:surya_ecommerce/personalization/brand/view/home_brand.dart';
import 'package:surya_ecommerce/personalization/category/view/home_category.dart';
import 'package:surya_ecommerce/routes/app_router.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final allProductsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<ProductModel>>(() {
      return ProductsNotifier();
    });

class ProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedBrandId;
  ProductSort _currentSort = ProductSort.newest;

  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedSubCategoryId => _selectedSubCategoryId;
  String? get selectedBrandId => _selectedBrandId;
  ProductSort get currentSort => _currentSort;

  @override
  Future<List<ProductModel>> build() async {
    return _fetchProducts();
  }

  Future<List<ProductModel>> _fetchProducts({bool isLoadMore = false}) async {
    try {
      var query = ref
          .watch(firestoreProvider)
          .collection('products')
          .where('isActive', isEqualTo: true);

      if (_selectedCategoryId != null) {
        query = query.where('productCategory', isEqualTo: _selectedCategoryId);
        if (_selectedSubCategoryId != null) {
          query = query.where(
            'subCategoryId',
            isEqualTo: _selectedSubCategoryId,
          );
        }
      }

      if (_selectedBrandId != null) {
        query = query.where('brandId', isEqualTo: _selectedBrandId);
      }

      query = query.orderBy(
        _currentSort.field,
        descending: _currentSort.descending,
      );

      if (_searchQuery.isNotEmpty) {
        final snapshot = await query.get();
        final allProducts = snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();

        final filtered = allProducts.where((p) {
          final name = p.productName.toLowerCase();
          final query = _searchQuery.toLowerCase().trim();
          final category = p.productCategory.toLowerCase();

          if (query.isEmpty) return true;

          if (name.contains(query) || category.contains(query)) return true;

          final queryWords = query.split(RegExp(r'\s+'));
          final nameWords = name.split(RegExp(r'\s+'));

          bool allWordsMatch = queryWords.every((qWord) {
            if (qWord.isEmpty) return true;
            return name.contains(qWord) || category.contains(qWord);
          });
          if (allWordsMatch) return true;

          for (var qWord in queryWords) {
            if (qWord.length < 3) continue;
            for (var nWord in nameWords) {
              if (nWord.length < 3) continue;
              if (qWord.contains(nWord) || nWord.contains(qWord)) return true;
            }
          }

          return false;
        }).toList();

        _hasMore = false;
        return filtered;
      }

      if (isLoadMore && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.limit(10).get();

      if (snapshot.docs.length < 10) {
        _hasMore = false;
      } else {
        _hasMore = true;
      }
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('🔥 FIRESTORE ERROR: $e');
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;

    final currentProducts = state.value ?? [];
    final moreProducts = await _fetchProducts(isLoadMore: true);
    state = AsyncData([...currentProducts, ...moreProducts]);
  }

  void updateFilters({
    String? search,
    String? categoryId,
    String? subCategoryId,
    String? brandId,
    ProductSort? sort,
    bool clearCategory = false,
    bool clearSubCategory = false,
    bool clearBrand = false,
  }) {
    _searchQuery = search ?? _searchQuery;

    if (clearCategory) {
      _selectedCategoryId = null;
      _selectedSubCategoryId = null;
    } else if (categoryId != null && categoryId != _selectedCategoryId) {
      _selectedCategoryId = categoryId;
      _selectedSubCategoryId = null;
    }

    if (clearSubCategory) {
      _selectedSubCategoryId = null;
    } else if (subCategoryId != null) {
      _selectedSubCategoryId = subCategoryId;
    }

    if (clearBrand) {
      _selectedBrandId = null;
    } else if (brandId != null) {
      _selectedBrandId = brandId;
    }

    _currentSort = sort ?? _currentSort;
    _lastDoc = null;
    _hasMore = true;
    ref.invalidateSelf();
  }
}

class AllProductsView extends ConsumerStatefulWidget {
  const AllProductsView({super.key});

  @override
  ConsumerState<AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends ConsumerState<AllProductsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(allProductsProvider.notifier).loadMore();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(allProductsProvider.notifier).updateFilters(search: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: "ALL PRODUCTS"),
      backgroundColor: AppColors.primaryDark,
      drawer: _buildFilterDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSearchRow(),
          if (productsAsync.isLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: AppColors.accentGold,
                backgroundColor: Colors.transparent,
                minHeight: 2,
              ),
            ),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          "https://cdn-icons-png.flaticon.com/128/14005/14005532.png",
                          height: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: GoogleFonts.nunito(
                            color: AppColors.softGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _buildGrid(products);
            },
            loading: () => _buildShimmerGrid(),
            error: (err, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        'Error: $err\n\nStacktrace: $stack',
                        style: GoogleFonts.outfit(
                          color: AppColors.softGrey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (productsAsync.value != null &&
              ref.watch(allProductsProvider.notifier).hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: LinearProgressIndicator(
                  color: AppColors.accentGold,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.nunito(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: GoogleFonts.nunito(color: AppColors.softGrey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.accentGold,
                  ),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderSoft.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<ProductModel> products) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 7 : 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ProductCard(product: products[index]),
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: AppColors.cardDark,
            highlightColor: AppColors.borderSoft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    ref.watch(allProductsProvider);
    final notifier = ref.read(allProductsProvider.notifier);
    final selectedCategoryId = notifier.selectedCategoryId;
    final selectedSubCategoryId = notifier.selectedSubCategoryId;
    final selectedBrandId = notifier.selectedBrandId;
    final currentSort = notifier.currentSort;
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 50),
          categoriesAsync.when(
            data: (categories) {
              final options = categories
                  .map((c) => DropdownOption(id: c.id, label: c.name))
                  .toList();
              return FilterDropdownField(
                label: 'CATEGORY',
                hintText: 'All categories',
                prefixIcon: Icons.grid_view_rounded,
                options: options,
                selectedId: selectedCategoryId,
                onSelected: (id) {
                  ref
                      .read(allProductsProvider.notifier)
                      .updateFilters(
                        categoryId: id,
                        clearCategory: id == null,
                      );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
            ),
            error: (e, s) => Text(
              'Error loading categories',
              style: GoogleFonts.outfit(color: AppColors.softGrey),
            ),
          ),
          if (selectedCategoryId != null) ...[
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, _) {
                final subCatsAsync =
                    ref.watch(subCategoriesProvider(selectedCategoryId));
                return subCatsAsync.when(
                  data: (subCats) {
                    final options = subCats
                        .map((s) =>
                            DropdownOption(id: s.id, label: s.name))
                        .toList();
                    return FilterDropdownField(
                      label: 'SUBCATEGORY',
                      hintText: 'All subcategories',
                      prefixIcon: Icons.category_outlined,
                      options: options,
                      selectedId: selectedSubCategoryId,
                      onSelected: (id) {
                        ref.read(allProductsProvider.notifier).updateFilters(
                              subCategoryId: id,
                              clearSubCategory: id == null,
                            );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentGold),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          brandsAsync.when(
            data: (brands) {
              final options = brands
                  .map((b) => DropdownOption(id: b.id, label: b.name))
                  .toList();
              return FilterDropdownField(
                label: 'BRAND',
                hintText: 'All brands',
                prefixIcon: Icons.local_offer_outlined,
                options: options,
                selectedId: selectedBrandId,
                onSelected: (id) {
                  ref
                      .read(allProductsProvider.notifier)
                      .updateFilters(
                        brandId: id,
                        clearBrand: id == null,
                      );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          FilterDropdownField(
            label: 'SORT BY',
            hintText: 'Newest First',
            prefixIcon: Icons.sort_rounded,
            options: ProductSort.values
                .map((s) => DropdownOption(id: s.name, label: s.label))
                .toList(),
            selectedId: currentSort.name,
            onSelected: (id) {
              if (id == null) return;
              final sort = ProductSort.values.firstWhere(
                (s) => s.name == id,
                orElse: () => ProductSort.newest,
              );
              ref
                  .read(allProductsProvider.notifier)
                  .updateFilters(sort: sort);
            },
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('APPLY FILTERS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => AppRouter.goProductDetails(context, product.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AppCachedImage(
                  url: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.productCategory,
                    style: GoogleFonts.nunito(
                      color: AppColors.softGrey,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${product.price}',
                    style: GoogleFonts.nunito(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
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

