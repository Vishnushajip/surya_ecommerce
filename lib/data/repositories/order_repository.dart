import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOrder(OrderModel order) async {
    try {
      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(order.toJson());
    } catch (e) {
      throw Exception('Failed to save order to Firestore: $e');
    }
  }

  Future<List<OrderModel>> getOrdersByPhone(String phone) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('phone', isEqualTo: phone)
          .get();

      final orders = querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
          
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders by phone: $e');
    }
  }
}
