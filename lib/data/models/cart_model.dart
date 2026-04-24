import 'product_model.dart';

class CartModel {
  final String id;
  final ProductModel product;
  final int quantity;
  final DateTime addedAt;

  const CartModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  // Factory constructor to create CartModel from JSON
  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as String,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  // Method to convert CartModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  CartModel copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  // Getters for computed properties
  double get totalPrice => product.price * quantity;
  String get formattedTotalPrice => '₹${totalPrice.toStringAsFixed(2)}';
  String get formattedItemPrice => product.formattedPrice;
  bool get isValid => product.isActive && product.isInStock;

  @override
  String toString() {
    return 'CartModel(id: $id, product: ${product.productName}, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CartSummary {
  final List<CartModel> items;
  final int totalItems;
  final double subtotal;
  final double grandTotal;
  final DateTime lastUpdated;

  const CartSummary({
    required this.items,
    required this.totalItems,
    required this.subtotal,
    required this.grandTotal,
    required this.lastUpdated,
  });

  // Factory constructor to create empty cart summary
  factory CartSummary.empty() {
    return CartSummary(
      items: [],
      totalItems: 0,
      subtotal: 0.0,
      grandTotal: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  // Factory constructor to create CartSummary from list of cart items
  factory CartSummary.fromItems(List<CartModel> cartItems) {
    final totalItems = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    
    return CartSummary(
      items: cartItems,
      totalItems: totalItems,
      subtotal: subtotal,
      grandTotal: subtotal, // No tax or shipping in this case
      lastUpdated: DateTime.now(),
    );
  }

  // Getters for computed properties
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';
  String get formattedGrandTotal => '₹${grandTotal.toStringAsFixed(2)}';
  int get uniqueItemCount => items.length;

  // Check if all items are valid (in stock and active)
  bool get allItemsValid => items.every((item) => item.isValid);

  // Get list of invalid items
  List<CartModel> get invalidItems => items.where((item) => !item.isValid).toList();

  // Get valid items only
  List<CartModel> get validItems => items.where((item) => item.isValid).toList();

  // Create a copy with updated fields
  CartSummary copyWith({
    List<CartModel>? items,
    int? totalItems,
    double? subtotal,
    double? grandTotal,
    DateTime? lastUpdated,
  }) {
    return CartSummary(
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      subtotal: subtotal ?? this.subtotal,
      grandTotal: grandTotal ?? this.grandTotal,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'CartSummary(totalItems: $totalItems, grandTotal: $formattedGrandTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartSummary && 
           other.totalItems == totalItems &&
           other.grandTotal == grandTotal;
  }

  @override
  int get hashCode => Object.hash(totalItems, grandTotal);
}

// Extension for cart utility methods
extension CartModelExtension on CartModel {
  // Check if quantity is within allowed limits
  bool get isValidQuantity => quantity > 0 && quantity <= 99;

  // Get quantity display text
  String get quantityDisplay => 'Qty: $quantity';

  // Check if item is available for purchase
  bool get isAvailableForPurchase => product.isInStock && product.isActive;

  // Get stock status message
  String get stockStatus {
    if (!product.isActive) return 'Product Unavailable';
    if (!product.isInStock) return 'Out of Stock';
    return 'In Stock';
  }
}

extension CartSummaryExtension on CartSummary {
  // Generate WhatsApp message for order
  String generateWhatsAppMessage({String customerName = 'Customer'}) {
    if (isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('🛒 *New Order - SUN Associates*');
    buffer.writeln('');
    buffer.writeln('👤 *Customer:* $customerName');
    buffer.writeln('📅 *Date:* ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('');
    buffer.writeln('📦 *Order Details:*');
    buffer.writeln('');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('${i + 1}. *${item.product.productName}*');
      buffer.writeln('   📝 Category: ${item.product.productCategory}');
      buffer.writeln('   💰 Price: ${item.formattedItemPrice}');
      buffer.writeln('   📊 Quantity: ${item.quantity}');
      buffer.writeln('   💵 Total: ${item.formattedTotalPrice}');
      buffer.writeln('');
    }

    buffer.writeln('💳 *Payment Summary:*');
    buffer.writeln('   📊 Items: $totalItems');
    buffer.writeln('   💰 Subtotal: $formattedSubtotal');
    buffer.writeln('   💵 Grand Total: $formattedGrandTotal');
    buffer.writeln('');
    buffer.writeln('📞 *Contact Information:*');
    buffer.writeln('   📱 Phone: +91 98765 43210');
    buffer.writeln('   📧 Email: info@sunassociates.com');
    buffer.writeln('');
    buffer.writeln('Thank you for your order! 🎉');

    return buffer.toString();
  }

  // Generate order summary text for display
  String generateOrderSummary({String customerName = 'Customer'}) {
    if (isEmpty) return 'No items in cart';

    final buffer = StringBuffer();
    buffer.writeln('ORDER SUMMARY');
    buffer.writeln('═' * 50);
    buffer.writeln('Customer: $customerName');
    buffer.writeln('Date: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('');
    buffer.writeln('ITEMS:');
    buffer.writeln('─' * 50);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('${i + 1}. ${item.product.productName}');
      buffer.writeln('   ${item.product.productCategory} | ${item.quantity} x ${item.formattedItemPrice} = ${item.formattedTotalPrice}');
    }

    buffer.writeln('─' * 50);
    buffer.writeln('Total Items: $totalItems');
    buffer.writeln('Subtotal: $formattedSubtotal');
    buffer.writeln('Grand Total: $formattedGrandTotal');
    buffer.writeln('═' * 50);

    return buffer.toString();
  }

  // Check if cart has any out-of-stock items
  bool get hasOutOfStockItems => items.any((item) => !item.product.isInStock);

  // Check if cart has any inactive items
  bool get hasInactiveItems => items.any((item) => !item.product.isActive);

  // Get items that need attention
  List<CartModel> get itemsNeedingAttention => 
      items.where((item) => !item.isValid).toList();
}
