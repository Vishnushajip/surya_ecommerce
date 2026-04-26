import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surya_ecommerce/core/theme/app_colors.dart';
import 'package:surya_ecommerce/core/responsive/responsive_helper.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import 'package:surya_ecommerce/data/models/product_model.dart';
import 'package:surya_ecommerce/main.dart';
import 'package:surya_ecommerce/personalization/home/widgets/product_card.dart';
import 'package:surya_ecommerce/personalization/category/view/home_category.dart';

final categoryProductsProvider =
    FutureProvider.family<List<ProductModel>, (String, String?)>((ref, arg) async {
      final categoryId = arg.$1;
      final subCategoryId = arg.$2;
      final repository = ref.watch(productRepositoryProvider);
      try {
        if (subCategoryId != null) {
          return await repository.getProductsBySubCategory(subCategoryId);
        }
        return await repository.getProductsByCategory(categoryId);
      } catch (e) {
        return [];
      }
    });

enum SortOption { none, priceLowHigh, priceHighLow, newest }

class _FilterState {
  final String searchQuery;
  final RangeValues priceRange;
  final SortOption sortOption;

  const _FilterState({
    this.searchQuery = '',
    this.priceRange = const RangeValues(0, 100000),
    this.sortOption = SortOption.none,
  });

  _FilterState copyWith({
    String? searchQuery,
    RangeValues? priceRange,
    SortOption? sortOption,
  }) {
    return _FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      priceRange: priceRange ?? this.priceRange,
      sortOption: sortOption ?? this.sortOption,
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
        return matchesSearch && matchesPrice;
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
    final productsAsync = ref.watch(categoryProductsProvider((category.id, subCategoryId)));
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
                      color: AppColors.softGrey.withOpacity(0.5),
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
}

class _ProductListBody extends ConsumerStatefulWidget {
  final List<ProductModel> products;
  final double maxPrice;
  final bool isMobile;
  final String displayName;

  const _ProductListBody({
    required this.products,
    required this.maxPrice,
    required this.isMobile,
    required this.displayName,
  });

  @override
  ConsumerState<_ProductListBody> createState() => _ProductListBodyState();
}

class _ProductListBodyState extends ConsumerState<_ProductListBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_filterProvider.notifier).reset(widget.maxPrice);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterBottomSheet(maxPrice: widget.maxPrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_filterProvider);
    final filtered = ref.watch(_filteredProductsProvider(widget.products));

    final isFiltered =
        filter.searchQuery.isNotEmpty ||
        filter.priceRange.start > 0 ||
        filter.priceRange.end < widget.maxPrice ||
        filter.sortOption != SortOption.none;

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
                onTap: _showFilterBottomSheet,
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
        const SizedBox(height: 10),
        _SortChips(isMobile: widget.isMobile),
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

                      return RepaintBoundary(
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
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SortChips extends ConsumerWidget {
  final bool isMobile;
  const _SortChips({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_filterProvider);

    final options = [
      (SortOption.none, 'Default'),
      (SortOption.priceLowHigh, 'Price: Low → High'),
      (SortOption.priceHighLow, 'Price: High → Low'),
      (SortOption.newest, 'Newest'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 64),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (option, label) = options[index];
          final isSelected = filter.sortOption == option;

          return GestureDetector(
            onTap: () =>
                ref.read(_filterProvider.notifier).setSortOption(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGold : AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentGold
                      : AppColors.borderSoft.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.softGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  final double maxPrice;
  const _FilterBottomSheet({required this.maxPrice});

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late RangeValues _localRange;

  @override
  void initState() {
    super.initState();
    _localRange = ref.read(_filterProvider).priceRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Filter by Price',
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.softGrey,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PriceTag(
                label: 'Min',
                value: '₹${_localRange.start.toStringAsFixed(0)}',
              ),
              _PriceTag(
                label: 'Max',
                value: '₹${_localRange.end.toStringAsFixed(0)}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentGold,
              inactiveTrackColor: AppColors.borderSoft.withValues(alpha: 0.3),
              thumbColor: AppColors.accentGold,
              overlayColor: AppColors.accentGold.withValues(alpha: 0.15),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              trackHeight: 4,
            ),
            child: RangeSlider(
              values: _localRange,
              min: 0,
              max: widget.maxPrice,
              divisions: 100,
              onChanged: (v) => setState(() => _localRange = v),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ref.read(_filterProvider.notifier).setPriceRange(_localRange);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'APPLY FILTER',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final String label;
  final String value;
  const _PriceTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.softGrey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
