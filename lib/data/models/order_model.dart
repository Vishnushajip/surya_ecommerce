import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final DateTime createdAt;
  final String customerName;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? email;
  final String paymentType;
  final String orderStatus;
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double tax;
  final double grandTotal;
  final List<OrderProductModel> products;

  OrderModel({
    required this.orderId,
    required this.createdAt,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.email,
    required this.paymentType,
    required this.orderStatus,
    required this.subtotal,
    required this.discount,
    required this.deliveryCharge,
    required this.tax,
    required this.grandTotal,
    required this.products,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      customerName: json['customerName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      email: json['email'],
      paymentType: json['paymentType'] ?? 'WhatsApp',
      orderStatus: json['orderStatus'] ?? 'Pending',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      deliveryCharge: (json['deliveryCharge'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0.0).toDouble(),
      products:
          (json['products'] as List<dynamic>?)
              ?.map(
                (e) => OrderProductModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'email': email,
      'paymentType': paymentType,
      'orderStatus': orderStatus,
      'subtotal': subtotal,
      'discount': discount,
      'deliveryCharge': deliveryCharge,
      'tax': tax,
      'grandTotal': grandTotal,
      'products': products.map((e) => e.toJson()).toList(),
    };
  }

  OrderModel copyWith({
    String? orderId,
    DateTime? createdAt,
    String? customerName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? email,
    String? paymentType,
    String? orderStatus,
    double? subtotal,
    double? discount,
    double? deliveryCharge,
    double? tax,
    double? grandTotal,
    List<OrderProductModel>? products,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      email: email ?? this.email,
      paymentType: paymentType ?? this.paymentType,
      orderStatus: orderStatus ?? this.orderStatus,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      products: products ?? this.products,
    );
  }
}

class OrderProductModel {
  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String itemCode;

  OrderProductModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.itemCode,
  });

  factory OrderProductModel.fromJson(Map<String, dynamic> json) {
    return OrderProductModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      itemCode: json['itemCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'itemCode': itemCode,
    };
  }
}
