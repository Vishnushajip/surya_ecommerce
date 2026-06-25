import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

final ordersViewModelProvider = StateNotifierProvider<OrdersViewModel, AsyncValue<List<OrderModel>>>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return OrdersViewModel(orderRepository);
});

class OrdersViewModel extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository _orderRepository;

  OrdersViewModel(this._orderRepository) : super(const AsyncValue.data([]));

  Future<void> fetchOrdersByPhone(String phone) async {
    state = const AsyncValue.loading();
    try {
      final orders = await _orderRepository.getOrdersByPhone(phone);
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
  }
}
