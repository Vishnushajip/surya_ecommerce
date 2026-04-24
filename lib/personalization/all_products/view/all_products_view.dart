import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/data/models/product_model.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final categoryListProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(firestoreProvider).collection('products').snapshots().map((
    snapshot,
  ) {
    final categories = snapshot.docs
        .map((doc) => doc.data()['categoryName'] as String? ?? 'Uncategorized')
        .toSet()
        .toList();
    categories.sort();
    return ['All', ...categories];
  });
});

final allProductsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<ProductModel>>(() {
      return ProductsNotifier();
    });

class ProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  ProductSort _currentSort = ProductSort.newest;

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

      // Filtering
      if (_selectedCategory != 'All') {
        query = query.where('categoryName', isEqualTo: _selectedCategory);
      }

      // Sorting
      query = query.orderBy(
        _currentSort.field,
        descending: _currentSort.descending,
      );

      // Pagination
      if (isLoadMore && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.limit(10).get();

      if (snapshot.docs.length < 10) _hasMore = false;
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      if (_searchQuery.isNotEmpty) {
        return products
            .where(
              (p) => p.productName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();
      }

      return products;
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

  void updateFilters({String? search, String? category, ProductSort? sort}) {
    _searchQuery = search ?? _searchQuery;
    _selectedCategory = category ?? _selectedCategory;
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
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ALL PRODUCTS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.accentGold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.primaryDark,
      drawer: _buildFilterDrawer(categoriesAsync),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSearchRow(),
          productsAsync.when(
            data: (products) => _buildGrid(products),
            loading: () => _buildShimmerGrid(),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SelectableText(
                    'Index Required or Error: $err',
                    style: GoogleFonts.nunito(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          if (productsAsync.value != null &&
              ref.watch(allProductsProvider.notifier).hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
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
            const SizedBox(width: 10),
            Builder(
              builder: (context) {
                return IconButton.filled(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.tune),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: Colors.black,
                  ),
                );
              },
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
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
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

  Widget _buildFilterDrawer(AsyncValue<List<String>> categoriesAsync) {
    return Drawer(
      backgroundColor: AppColors.primaryDark,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 50),
          Text(
            'FILTER BY CATEGORY',
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: AppColors.borderSoft),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 8,
              children: categories
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ActionChip(
                        label: Text(cat),
                        onPressed: () {
                          ref
                              .read(allProductsProvider.notifier)
                              .updateFilters(category: cat);
                          Navigator.pop(context);
                        },
                        backgroundColor: AppColors.cardDark,
                        labelStyle: GoogleFonts.outfit(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => const Text('Error loading categories'),
          ),
          const SizedBox(height: 30),
          Text(
            'SORT BY',
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: AppColors.borderSoft),
          ...ProductSort.values.map(
            (sort) => ListTile(
              title: Text(
                sort.label,
                style: GoogleFonts.nunito(color: Colors.white),
              ),
              onTap: () {
                ref
                    .read(allProductsProvider.notifier)
                    .updateFilters(sort: sort);
                Navigator.pop(context);
              },
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
    return Container(
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
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.softGrey,
                      ),
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
    );
  }
}

enum ProductSort {
  newest('Newest First', 'createdDate', true),
  oldest('Oldest First', 'createdDate', false),
  priceLow('Price: Low to High', 'price', false),
  priceHigh('Price: High to Low', 'price', true),
  rating('Top Rated', 'ratingAverage', true);

  final String label;
  final String field;
  final bool descending;
  const ProductSort(this.label, this.field, this.descending);
}
