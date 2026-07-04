import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../models/cart_model.dart';

final orderServiceProvider =
    Provider<OrderService>(
  (ref) => OrderService(),
);

final orderProvider =
    AsyncNotifierProvider<
        OrderController,
        List<CashierOrder>>(
  OrderController.new,
);

class OrderController extends AsyncNotifier<List<CashierOrder>> {
  late final OrderService _service;

  @override
  Future<List<CashierOrder>> build() async {
    _service = ref.read(
      orderServiceProvider,
    );

    return _service.getOrders();
  }

  CashierOrder get selectedOrder {
    if (state.value == null || state.value!.isEmpty) {
      return CashierOrder.empty();
    }

    return state.value!.first;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _service.getOrders(),
    );
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _service.updateOrderStatus(
      orderId: orderId,
      status: status,
    );

    await refresh();
  }

  Future<void> addOrder({
    required String customer,
    required String note,
    required CartState cart,
  }) async {
    await _service.addOrder(
      customer: customer,
      note: note,
      total: cart.total,
      items: cart.lines
          .map(
            (line) => {
              'menu_id': line.product.id,
              'quantity': line.quantity,
              'price': line.product.price,
              'subtotal': line.subtotal,
            },
          )
          .toList(),
    );

    await refresh();
  }
  Future<void> markOrderReady(
    String orderId,
  ) async {
    await _service.updateOrderStatus(
      orderId: orderId,
      status: 'ready',
    );

    await refresh();
  }

  Future<void> markOrderPreparing(
    String orderId,
  ) async {
    await _service.updateOrderStatus(
      orderId: orderId,
      status: 'preparing',
    );

    await refresh();
  }

  Future<void> markOrderPickedUp(
    String orderId,
  ) async {
    await _service.updateOrderStatus(
      orderId: orderId,
      status: 'completed',
    );

    await refresh();
  }
}