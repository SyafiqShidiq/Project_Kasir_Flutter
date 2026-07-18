import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../models/cart_model.dart';
import 'current_order_provider.dart';

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
  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    return await _service.getActiveOrders();
  }
  
  Future<Map<String, dynamic>?> loadActiveOrder() async {
    final orders = await _service.getActiveOrders();

    if (orders.isEmpty) {
      return null;
    }

    return orders.first;
  }
  Future<Map<String, dynamic>?> refreshCurrentOrder() async {
    final order = await loadActiveOrder();
    return order;
  }
  Future<void> restoreCurrentOrder() async {
    print('=== RESTORE CURRENT ORDER ===');
    final order = await loadActiveOrder();

    final notifier = ref.read(
      currentOrderProvider.notifier,
    );

    if (order == null) {
      print('Tidak ada invoice aktif');
      notifier.clear();
    } else {
      print(
        'Invoice ditemukan: ${order['order_number']}',
      );
      notifier.setOrder(order);
    }
    print('=== RESTORE SELESAI ===');
  }

  Future<Map<String, dynamic>> addOrder({
    required String customer,
    required String orderType,
    int? tableNumber,
    required CartState cart,
  }) async {
    final order = await _service.addOrder(
      customer: customer,
      orderType: orderType,
      tableNumber: tableNumber,
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
    return order;
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