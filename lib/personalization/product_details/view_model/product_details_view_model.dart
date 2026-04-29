import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../main.dart';

final productDetailsViewModelProvider =
    StateNotifierProvider.family<
      ProductDetailsViewModel,
      AsyncValue<ProductModel?>,
      String
    >((ref, productId) {
      final productRepository = ref.watch(productRepositoryProvider);
      return ProductDetailsViewModel(productRepository, productId);
    });

final suggestedProductsProvider =
    StateNotifierProvider.family<
      SuggestedProductsViewModel,
      AsyncValue<ProductsPage>,
      String
    >((ref, productId) {
      final productRepository = ref.watch(productRepositoryProvider);
      return SuggestedProductsViewModel(productRepository, productId, ref);
    });

class SuggestedProductsViewModel extends StateNotifier<AsyncValue<ProductsPage>> {
  final ProductRepository _productRepository;
  final String productId;
  final Ref ref;

  SuggestedProductsViewModel(this._productRepository, this.productId, this.ref)
    : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final productAsync = ref.read(productDetailsViewModelProvider(productId));
      final product = productAsync.value;
      
      if (product == null) {
        state = AsyncValue.data(ProductRepository.productsPage(items: [], lastDocument: null, hasMore: false));
        return;
      }

      var page = await _productRepository.getSuggestedProductsPage(
        productId,
        product.productCategory,
        subCategoryId: product.subCategoryId,
      );

      if (page.items.isEmpty) {
        final featured = await _productRepository.getProductsPage(featured: true, limit: 6);
        page = ProductsPage(
          items: featured.items.where((p) => p.id != productId).toList(),
          lastDocument: featured.lastDocument,
          hasMore: featured.hasMore,
        );
      }

      state = AsyncValue.data(page);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;

    try {
      final product = ref.read(productDetailsViewModelProvider(productId)).value!;
      
      final nextPage = await _productRepository.getSuggestedProductsPage(
        productId,
        product.productCategory,
        subCategoryId: product.subCategoryId,
        startAfter: current.lastDocument,
      );

      state = AsyncValue.data(ProductRepository.productsPage(
        items: [...current.items, ...nextPage.items],
        lastDocument: nextPage.lastDocument,
        hasMore: nextPage.hasMore,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class ProductDetailsViewModel extends StateNotifier<AsyncValue<ProductModel?>> {
  final ProductRepository _productRepository;
  final String productId;

  ProductDetailsViewModel(this._productRepository, this.productId)
    : super(const AsyncValue.loading()) {
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      state = const AsyncValue.loading();
      final product = await _productRepository.getProductById(productId);
      state = AsyncValue.data(product);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadProduct();
  }
}
