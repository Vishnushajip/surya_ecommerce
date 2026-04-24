import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../../core/constants/app_constants.dart';

class CartRepository {
  static const String _cartKey = 'cart_items';
  static const String _cartTimestampKey = 'cart_timestamp';

  final SharedPreferences _prefs;

  CartRepository(this._prefs);

  // Get all cart items
  Future<List<CartModel>> getCartItems() async {
    try {
      // Check for 24-hour auto-clear
      final timestampString = _prefs.getString(_cartTimestampKey);
      if (timestampString != null) {
        final lastUpdated = DateTime.parse(timestampString);
        final difference = DateTime.now().difference(lastUpdated);
        if (difference.inHours >= 24) {
          await clearCart();
          return [];
        }
      }

      final cartJson = _prefs.getString(_cartKey);
      if (cartJson == null) return [];

      final cartData = jsonDecode(cartJson) as List;
      return cartData
          .map((item) => CartModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return []; // Return empty instead of throwing to avoid crashes
    }
  }

  // Save cart items
  Future<void> saveCartItems(List<CartModel> items) async {
    try {
      final cartJson = jsonEncode(items.map((item) => item.toJson()).toList());

      await _prefs.setString(_cartKey, cartJson);
      await _prefs.setString(
        _cartTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to save cart items: $e');
    }
  }

  // Add item to cart
  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    try {
      final cartItems = await getCartItems();

      // Check if item already exists
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = cartItems[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;

        if (newQuantity > AppConstants.maxCartItemQuantity) {
          throw Exception('Maximum quantity limit reached');
        }

        cartItems[existingItemIndex] = existingItem.copyWith(
          quantity: newQuantity,
        );
      } else {
        // Add new item
        final cartItem = CartModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: quantity,
          addedAt: DateTime.now(),
        );
        cartItems.add(cartItem);
      }

      await saveCartItems(cartItems);
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  // Update item quantity
  Future<void> updateItemQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0 || quantity > AppConstants.maxCartItemQuantity) {
        throw Exception('Invalid quantity');
      }

      final cartItems = await getCartItems();
      final itemIndex = cartItems.indexWhere((item) => item.id == cartItemId);

      if (itemIndex == -1) {
        throw Exception('Item not found in cart');
      }

      cartItems[itemIndex] = cartItems[itemIndex].copyWith(quantity: quantity);
      await saveCartItems(cartItems);
    } catch (e) {
      throw Exception('Failed to update item quantity: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      final cartItems = await getCartItems();
      cartItems.removeWhere((item) => item.id == cartItemId);
      await saveCartItems(cartItems);
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      await _prefs.remove(_cartKey);
      await _prefs.remove(_cartTimestampKey);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get cart summary
  Future<CartSummary> getCartSummary() async {
    try {
      final cartItems = await getCartItems();
      return CartSummary.fromItems(cartItems);
    } catch (e) {
      throw Exception('Failed to get cart summary: $e');
    }
  }

  // Get item count
  Future<int> getCartItemCount() async {
    try {
      final cartItems = await getCartItems();
      return cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      throw Exception('Failed to get cart item count: $e');
    }
  }

  // Check if product is in cart
  Future<bool> isProductInCart(String productId) async {
    try {
      final cartItems = await getCartItems();
      return cartItems.any((item) => item.product.id == productId);
    } catch (e) {
      throw Exception('Failed to check if product is in cart: $e');
    }
  }

  // Get cart item for a product
  Future<CartModel?> getCartItemForProduct(String productId) async {
    try {
      final cartItems = await getCartItems();
      return cartItems.firstWhere(
        (item) => item.product.id == productId,
        orElse: () => throw Exception('Item not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Get cart timestamp
  Future<DateTime?> getCartTimestamp() async {
    try {
      final timestampString = _prefs.getString(_cartTimestampKey);
      if (timestampString == null) return null;
      return DateTime.parse(timestampString);
    } catch (e) {
      return null;
    }
  }

  // Clean expired cart items (older than 30 days)
  Future<void> cleanExpiredCartItems() async {
    try {
      final cartItems = await getCartItems();
      final now = DateTime.now();

      final validItems = cartItems.where((item) {
        final daysDifference = now.difference(item.addedAt).inDays;
        return daysDifference <= AppConstants.cartPersistenceDuration.inDays;
      }).toList();

      if (validItems.length != cartItems.length) {
        await saveCartItems(validItems);
      }
    } catch (e) {
      throw Exception('Failed to clean expired cart items: $e');
    }
  }

  // Remove invalid items (out of stock or inactive products)
  Future<void> removeInvalidItems() async {
    try {
      final cartItems = await getCartItems();
      final validItems = cartItems.where((item) => item.isValid).toList();

      if (validItems.length != cartItems.length) {
        await saveCartItems(validItems);
      }
    } catch (e) {
      throw Exception('Failed to remove invalid items: $e');
    }
  }

  // Get cart statistics
  Future<Map<String, dynamic>> getCartStatistics() async {
    try {
      final cartSummary = await getCartSummary();
      final cartTimestamp = await getCartTimestamp();

      return {
        'totalItems': cartSummary.totalItems,
        'uniqueItems': cartSummary.uniqueItemCount,
        'subtotal': cartSummary.subtotal,
        'grandTotal': cartSummary.grandTotal,
        'lastUpdated': cartSummary.lastUpdated.toIso8601String(),
        'cartAge': cartTimestamp != null
            ? DateTime.now().difference(cartTimestamp).inDays
            : null,
        'hasInvalidItems': cartSummary.itemsNeedingAttention.isNotEmpty,
        'invalidItemCount': cartSummary.itemsNeedingAttention.length,
      };
    } catch (e) {
      throw Exception('Failed to get cart statistics: $e');
    }
  }

  // Merge cart items (useful for guest checkout scenarios)
  Future<void> mergeCartItems(List<CartModel> additionalItems) async {
    try {
      final existingCartItems = await getCartItems();

      for (final newItem in additionalItems) {
        final existingItemIndex = existingCartItems.indexWhere(
          (item) => item.product.id == newItem.product.id,
        );

        if (existingItemIndex != -1) {
          // Update existing item quantity
          final existingItem = existingCartItems[existingItemIndex];
          final newQuantity = existingItem.quantity + newItem.quantity;

          if (newQuantity <= AppConstants.maxCartItemQuantity) {
            existingCartItems[existingItemIndex] = existingItem.copyWith(
              quantity: newQuantity,
            );
          }
        } else {
          // Add new item
          existingCartItems.add(newItem);
        }
      }

      await saveCartItems(existingCartItems);
    } catch (e) {
      throw Exception('Failed to merge cart items: $e');
    }
  }

  // Validate cart items
  Future<List<String>> validateCartItems() async {
    try {
      final cartItems = await getCartItems();
      final List<String> issues = [];

      for (final item in cartItems) {
        if (!item.product.isActive) {
          issues.add('${item.product.productName} is no longer available');
        }

        if (!item.product.isInStock) {
          issues.add('${item.product.productName} is out of stock');
        }

        if (!item.isValidQuantity) {
          issues.add('${item.product.productName} has invalid quantity');
        }
      }

      return issues;
    } catch (e) {
      throw Exception('Failed to validate cart items: $e');
    }
  }

  // Backup cart (for migration scenarios)
  Future<String> backupCart() async {
    try {
      final cartItems = await getCartItems();
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'items': cartItems.map((item) => item.toJson()).toList(),
      };
      return jsonEncode(backupData);
    } catch (e) {
      throw Exception('Failed to backup cart: $e');
    }
  }

  // Restore cart from backup
  Future<void> restoreCart(String backupData) async {
    try {
      final data = jsonDecode(backupData) as Map<String, dynamic>;
      final itemsData = data['items'] as List;

      final items = itemsData
          .map((item) => CartModel.fromJson(item as Map<String, dynamic>))
          .toList();

      await saveCartItems(items);
    } catch (e) {
      throw Exception('Failed to restore cart: $e');
    }
  }
}
