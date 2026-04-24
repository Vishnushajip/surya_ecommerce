import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cart_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../main.dart';

final cartViewModelProvider =
    StateNotifierProvider<CartViewModel, AsyncValue<CartSummary>>((ref) {
      final cartRepository = ref.watch(cartRepositoryProvider);
      return CartViewModel(cartRepository);
    });

class CartViewModel extends StateNotifier<AsyncValue<CartSummary>> {
  final CartRepository _cartRepository;

  CartViewModel(this._cartRepository) : super(const AsyncValue.loading()) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      if (state.hasValue) {
      } else {
        state = const AsyncValue.loading();
      }
      
      final cartSummary = await _cartRepository.getCartSummary();
      state = AsyncValue.data(cartSummary);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    try {
      await _cartRepository.addToCart(product, quantity: quantity);
      await _loadCart();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      await _cartRepository.updateItemQuantity(cartItemId, quantity);
      await _loadCart();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _cartRepository.removeFromCart(cartItemId);
      await _loadCart();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartRepository.clearCart();
      await _loadCart();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<int> getCartItemCount() async {
    try {
      return await _cartRepository.getCartItemCount();
    } catch (e) {
      return 0;
    }
  }

  Future<bool> isProductInCart(String productId) async {
    try {
      return await _cartRepository.isProductInCart(productId);
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshCart() async {
    await _loadCart();
  }
}
