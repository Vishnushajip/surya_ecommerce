import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import 'package:surya_ecommerce/core/widgets/filter_dropdown_field.dart';
import 'package:surya_ecommerce/data/models/product_model.dart';
import 'package:surya_ecommerce/personalization/brand/view/home_brand.dart';
import 'package:surya_ecommerce/personalization/category/view/home_category.dart';
import '../../home/widgets/product_card.dart';

final brandProductsProvider =
    AsyncNotifierProvider.family<
      BrandProductsNotifier,
      List<ProductModel>,
      String
    >(() {
      return BrandProductsNotifier();
    });

class BrandProductsNotifier
    extends FamilyAsyncNotifier<List<ProductModel>, String> {
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _searchQuery = '';
  String? _selectedCategoryId;
  ProductSort _currentSort = ProductSort.newest;

  String? get selectedCategoryId => _selectedCategoryId;
  ProductSort get currentSort => _currentSort;

  @override
  Future<List<ProductModel>> build(String arg) async {
    return _fetchProducts(arg);
  }

  Future<List<ProductModel>> _fetchProducts(
    String brandId, {
    bool isLoadMore = false,
  }) async {
    try {
      var query = FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('brandId', isEqualTo: brandId);

      if (_selectedCategoryId != null) {
        query = query.where('productCategory', isEqualTo: _selectedCategoryId);
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
          final q = _searchQuery.toLowerCase().trim();
          return name.contains(q) ||
              p.productCategory.toLowerCase().contains(q);
        }).toList();

        _hasMore = false;
        return filtered;
      }

      if (isLoadMore && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.limit(12).get();

      if (snapshot.docs.length < 12) {
        _hasMore = false;
      } else {
        _hasMore = true;
      }
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('🔥 BRAND PRODUCTS ERROR: $e');
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;

    final currentProducts = state.value ?? [];
    final moreProducts = await _fetchProducts(arg, isLoadMore: true);
    state = AsyncData([...currentProducts, ...moreProducts]);
  }

  void updateFilters({
    String? search,
    String? categoryId,
    ProductSort? sort,
    bool clearCategory = false,
  }) {
    _searchQuery = search ?? _searchQuery;

    if (clearCategory) {
      _selectedCategoryId = null;
    } else if (categoryId != null) {
      _selectedCategoryId = categoryId;
    }

    _currentSort = sort ?? _currentSort;
    _lastDoc = null;
    _hasMore = true;
    ref.invalidateSelf();
  }
}

class BrandProductsView extends ConsumerStatefulWidget {
  final BrandModel brand;
  const BrandProductsView({super.key, required this.brand});

  @override
  ConsumerState<BrandProductsView> createState() => _BrandProductsViewState();
}

class _BrandProductsViewState extends ConsumerState<BrandProductsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(brandProductsProvider(widget.brand.id).notifier).loadMore();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(brandProductsProvider(widget.brand.id).notifier)
          .updateFilters(search: query);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(brandProductsProvider(widget.brand.id));

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.brand.name.toUpperCase(),
        showBackButton: true,
      ),
      backgroundColor: AppColors.primaryDark,
      drawer: _buildFilterDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildBrandHeader(),
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
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.softGrey,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
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
                child: SelectableText(
                  'Error: $err',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          if (productsAsync.value != null &&
              ref
                  .watch(brandProductsProvider(widget.brand.id).notifier)
                  .hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            if (widget.brand.imageUrl.isNotEmpty)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  widget.brand.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.brand.name,
                    style: GoogleFonts.outfit(
                      color: AppColors.accentGold,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Explore premium products from ${widget.brand.name}',
                    style: GoogleFonts.outfit(
                      color: AppColors.softGrey,
                      fontSize: 14,
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
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.brand.name}...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.softGrey),
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
                      color: AppColors.borderSoft.withOpacity(0.3),
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
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 6 : 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(product: products[index]),
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
    final notifier = ref.read(brandProductsProvider(widget.brand.id).notifier);
    final selectedCategoryId = notifier.selectedCategoryId;
    final currentSort = notifier.currentSort;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 50),
          Text(
            'FILTERS',
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
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
                      .read(brandProductsProvider(widget.brand.id).notifier)
                      .updateFilters(categoryId: id, clearCategory: id == null);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            ),
            error: (e, s) => const Text('Error loading categories'),
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
              final sort = ProductSort.values.firstWhere((s) => s.name == id);
              ref
                  .read(brandProductsProvider(widget.brand.id).notifier)
                  .updateFilters(sort: sort);
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'APPLY FILTERS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
