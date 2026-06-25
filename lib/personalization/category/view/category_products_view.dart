import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/core/responsive/responsive_helper.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import 'package:surya_ecommerce/core/widgets/filter_dropdown_field.dart';
import 'package:surya_ecommerce/data/models/product_model.dart';
import 'package:surya_ecommerce/main.dart';
import 'package:surya_ecommerce/personalization/brand/view/home_brand.dart';
import 'package:surya_ecommerce/personalization/home/widgets/product_card.dart';
import 'package:surya_ecommerce/personalization/category/view/home_category.dart';

class CategoryProductsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ProductModel>, String> {
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<ProductModel>> build(String categoryId) async {
    _lastDoc = null;
    _hasMore = true;
    final repository = ref.watch(productRepositoryProvider);
    try {
      final page = await repository.getProductsByCategoryPage(categoryId);
      _lastDoc = page.lastDocument;
      _hasMore = page.hasMore;
      return page.items;
    } catch (_) {
      _hasMore = false;
      return [];
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.value ?? [];
    try {
      final repository = ref.read(productRepositoryProvider);
      final page = await repository.getProductsByCategoryPage(
        arg,
        startAfter: _lastDoc,
      );
      _lastDoc = page.lastDocument;
      _hasMore = page.hasMore;
      state = AsyncData([...current, ...page.items]);
    } catch (_) {
      _hasMore = false;
    }
  }
}

final categoryProductsProvider = AsyncNotifierProvider.autoDispose
    .family<CategoryProductsNotifier, List<ProductModel>, String>(
      CategoryProductsNotifier.new,
    );

enum SortOption { none, priceLowHigh, priceHighLow, newest, brand }

class _FilterState {
  final String searchQuery;
  final RangeValues priceRange;
  final SortOption sortOption;
  final String? selectedSubCategoryId;
  final String? selectedBrandId;

  const _FilterState({
    this.searchQuery = '',
    this.priceRange = const RangeValues(0, 100000),
    this.sortOption = SortOption.none,
    this.selectedSubCategoryId,
    this.selectedBrandId,
  });

  _FilterState copyWith({
    String? searchQuery,
    RangeValues? priceRange,
    SortOption? sortOption,
    String? selectedSubCategoryId,
    String? selectedBrandId,
    bool clearSubCategory = false,
    bool clearBrand = false,
  }) {
    return _FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      priceRange: priceRange ?? this.priceRange,
      sortOption: sortOption ?? this.sortOption,
      selectedSubCategoryId: clearSubCategory
          ? null
          : (selectedSubCategoryId ?? this.selectedSubCategoryId),
      selectedBrandId: clearBrand
          ? null
          : (selectedBrandId ?? this.selectedBrandId),
    );
  }
}

class _FilterNotifier extends StateNotifier<_FilterState> {
  _FilterNotifier() : super(const _FilterState());

  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void setPriceRange(RangeValues range) =>
      state = state.copyWith(priceRange: range);
  void setSortOption(SortOption option) =>
      state = state.copyWith(sortOption: option);
  void setSubCategory(String? id) => state = state.copyWith(
    selectedSubCategoryId: id,
    clearSubCategory: id == null,
  );
  void setBrand(String? id) => state = state.copyWith(
    selectedBrandId: id,
    clearBrand: id == null,
  );
  void reset(double maxPrice) =>
      state = _FilterState(priceRange: RangeValues(0, maxPrice));
}

final _filterProvider =
    StateNotifierProvider.autoDispose<_FilterNotifier, _FilterState>(
      (ref) => _FilterNotifier(),
    );

final _filteredProductsProvider = Provider.autoDispose
    .family<List<ProductModel>, List<ProductModel>>((ref, products) {
      final filter = ref.watch(_filterProvider);

      var result = products.where((p) {
        final matchesSearch =
            filter.searchQuery.isEmpty ||
            p.productName.toLowerCase().contains(
              filter.searchQuery.toLowerCase(),
            );
        final matchesPrice =
            p.price >= filter.priceRange.start &&
            p.price <= filter.priceRange.end;

        final matchesSubCategory =
            filter.selectedSubCategoryId == null ||
            p.subCategoryId == filter.selectedSubCategoryId;

        final matchesBrand =
            filter.selectedBrandId == null ||
            p.brandId == filter.selectedBrandId;

        return matchesSearch &&
            matchesPrice &&
            matchesSubCategory &&
            matchesBrand;
      }).toList();

      switch (filter.sortOption) {
        case SortOption.priceLowHigh:
          result.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortOption.priceHighLow:
          result.sort((a, b) => b.price.compareTo(a.price));
          break;
        case SortOption.newest:
          result.sort((a, b) => b.createdDate.compareTo(a.createdDate));
          break;
        case SortOption.brand:
          result.sort(
            (a, b) => (a.brandName ?? '~').toLowerCase().compareTo(
              (b.brandName ?? '~').toLowerCase(),
            ),
          );
          break;
        case SortOption.none:
          break;
      }

      return result;
    });

class CategoryProductsView extends ConsumerWidget {
  final CategoryModel category;
  final String? subCategoryId;

  const CategoryProductsView({
    super.key,
    required this.category,
    this.subCategoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(categoryProductsProvider(category.id));
    final categoriesAsync = ref.watch(categoriesProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    String displayName = category.name;
    if (displayName.isEmpty) {
      displayName = categoriesAsync.maybeWhen(
        data: (cats) => cats
            .firstWhere((c) => c.id == category.id, orElse: () => category)
            .name,
        orElse: () => '',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: displayName),
      endDrawer: _buildFilterDrawer(context, ref, categoriesAsync, category),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.softGrey.withValues(alpha: 0.5),
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'NO PRODUCTS FOUND',
                      style: GoogleFonts.outfit(
                        color: AppColors.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are currently no products available in the ${displayName.toLowerCase()} collection.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        color: AppColors.softGrey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final maxPrice = products
              .map((p) => p.price)
              .reduce((a, b) => a > b ? a : b);

          return _ProductListBody(
            products: products,
            maxPrice: maxPrice,
            isMobile: isMobile,
            displayName: displayName,
            subCategoryId: subCategoryId,
            category: category,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error loading products: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDrawer(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CategoryModel>> categoriesAsync,
    CategoryModel currentCategory,
  ) {
    final filter = ref.watch(_filterProvider);
    final subCategoriesAsync = ref.watch(
      subCategoriesProvider(currentCategory.id),
    );
    final brandsAsync = ref.watch(brandsByCategoryProvider(currentCategory.id));

    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 50),
          subCategoriesAsync.when(
            data: (subCats) {
              final options = [
                ...subCats.map((s) => DropdownOption(id: s.id, label: s.name)),
              ];
              return FilterDropdownField(
                label: 'SUBCATEGORY',
                hintText: 'All subcategories',
                prefixIcon: Icons.category_outlined,
                options: options,
                selectedId: filter.selectedSubCategoryId,
                onSelected: (id) {
                  ref.read(_filterProvider.notifier).setSubCategory(id);
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
          brandsAsync.when(
            data: (brands) {
              if (brands.isEmpty) return const SizedBox.shrink();
              final options = brands
                  .map((b) => DropdownOption(id: b.id, label: b.name))
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilterDropdownField(
                    label: 'BRAND',
                    hintText: 'All brands',
                    prefixIcon: Icons.local_offer_outlined,
                    options: options,
                    selectedId: filter.selectedBrandId,
                    onSelected: (id) {
                      ref.read(_filterProvider.notifier).setBrand(id);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
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
          FilterDropdownField(
            label: 'SORT BY',
            hintText: 'Default',
            prefixIcon: Icons.sort_rounded,
            options: const [
              DropdownOption(id: 'priceLowHigh', label: 'Price: Low to High'),
              DropdownOption(id: 'priceHighLow', label: 'Price: High to Low'),
              DropdownOption(id: 'newest', label: 'Newest First'),
              DropdownOption(id: 'brand', label: 'Brand (A–Z)'),
            ],
            selectedId: filter.sortOption == SortOption.none
                ? null
                : filter.sortOption.name,
            onSelected: (id) {
              final option = id == null
                  ? SortOption.none
                  : SortOption.values.firstWhere(
                      (o) => o.name == id,
                      orElse: () => SortOption.none,
                    );
              ref.read(_filterProvider.notifier).setSortOption(option);
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

class _ProductListBody extends ConsumerStatefulWidget {
  final List<ProductModel> products;
  final double maxPrice;
  final bool isMobile;
  final String displayName;
  final String? subCategoryId;
  final CategoryModel category;

  const _ProductListBody({
    required this.products,
    required this.maxPrice,
    required this.isMobile,
    required this.displayName,
    required this.category,
    this.subCategoryId,
  });

  @override
  ConsumerState<_ProductListBody> createState() => _ProductListBodyState();
}

class _ProductListBodyState extends ConsumerState<_ProductListBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_filterProvider.notifier).reset(widget.maxPrice);
      if (widget.subCategoryId != null) {
        ref.read(_filterProvider.notifier).setSubCategory(widget.subCategoryId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _maybeLoadMore();
    }
  }

  Future<void> _maybeLoadMore() async {
    if (_isLoadingMore) return;
    final notifier = ref.read(
      categoryProductsProvider(widget.category.id).notifier,
    );
    if (!notifier.hasMore) return;
    setState(() => _isLoadingMore = true);
    await notifier.loadMore();
    if (!mounted) return;
    setState(() => _isLoadingMore = false);
  }

  void _showFilterSidebar() {
    Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_filterProvider);
    final filtered = ref.watch(_filteredProductsProvider(widget.products));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) {
        _maybeLoadMore();
      }
    });

    final isFiltered =
        filter.searchQuery.isNotEmpty ||
        filter.priceRange.start > 0 ||
        filter.priceRange.end < widget.maxPrice ||
        filter.sortOption != SortOption.none ||
        filter.selectedSubCategoryId != null ||
        filter.selectedBrandId != null;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.isMobile ? 16 : 64,
            12,
            widget.isMobile ? 16 : 64,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderSoft.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        ref.read(_filterProvider.notifier).setSearch(v),
                    style: GoogleFonts.outfit(
                      color: AppColors.textWhite,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: GoogleFonts.outfit(
                        color: AppColors.softGrey.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.softGrey.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      suffixIcon: filter.searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref
                                    .read(_filterProvider.notifier)
                                    .setSearch('');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.softGrey,
                                size: 18,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showFilterSidebar,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: isFiltered
                        ? AppColors.accentGold
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFiltered
                          ? AppColors.accentGold
                          : AppColors.borderSoft.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: isFiltered
                        ? AppColors.primaryDark
                        : AppColors.softGrey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 64),
          child: Row(
            children: [
              Text(
                '${filtered.length} Products',
                style: GoogleFonts.outfit(
                  color: AppColors.softGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isFiltered) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    ref.read(_filterProvider.notifier).reset(widget.maxPrice);
                  },
                  child: Text(
                    'Clear Filters',
                    style: GoogleFonts.outfit(
                      color: AppColors.accentGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        color: AppColors.softGrey.withValues(alpha: 0.4),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: GoogleFonts.outfit(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try adjusting your search or filters',
                        style: GoogleFonts.outfit(
                          color: AppColors.softGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 16 : 64,
                    vertical: 4,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final spacing = widget.isMobile ? 12.0 : 20.0;
                      final crossAxisCount = widget.isMobile
                          ? 2
                          : (constraints.maxWidth > 1200 ? 5 : 4);
                      final itemWidth =
                          (constraints.maxWidth -
                              spacing * (crossAxisCount - 1)) /
                          crossAxisCount;

                      final hasMore = ref
                          .watch(
                            categoryProductsProvider(
                              widget.category.id,
                            ).notifier,
                          )
                          .hasMore;

                      return Column(
                        children: [
                          RepaintBoundary(
                            child: Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: filtered.map((product) {
                                return SizedBox(
                                  width: itemWidth,
                                  child: ProductCard(product: product),
                                );
                              }).toList(),
                            ),
                          ),
                          if (hasMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
