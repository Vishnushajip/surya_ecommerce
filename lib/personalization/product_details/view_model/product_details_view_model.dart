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

final relatedProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, productId) async {
      final productRepository = ref.watch(productRepositoryProvider);
      final productAsync = ref.watch(
        productDetailsViewModelProvider(productId),
      );

      return productAsync.when(
        data: (product) {
          if (product == null) return [];
          return productRepository.getRelatedProducts(
            productId,
            product.productCategory,
            limit: 6,
          );
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });

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
