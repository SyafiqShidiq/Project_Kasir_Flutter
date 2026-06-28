import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<CashierOrder>> getOrders() async {
    final ordersData = await _supabase
        .from('orders')
        .select()
        .order(
          'created_at',
          ascending: false,
        );

    List<CashierOrder> orders = [];

    for (final orderJson in ordersData) {
      final itemsData = await _supabase
          .from('order_items')
          .select()
          .eq(
            'order_id',
            orderJson['id'],
          );

      final items =
          itemsData
              .map<OrderItem>(
                (item) => OrderItem(
                  name: item['menu_id'] ?? '',
                  quantity: item['quantity'] ?? 0,
                  subtotal: item['subtotal'] ?? 0,
                ),
              )
              .toList();

      orders.add(
        CashierOrder.fromOrderJson(
          orderJson: orderJson,
          items: items,
        ),
      );
    }

    return orders;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _supabase
        .from('orders')
        .update({
          'order_status': status,
        })
        .eq(
          'id',
          orderId,
        );
  }

  Future<void> addOrder({
    required String note,
    required int total,
    required List<Map<String, dynamic>> items,
  }) async {
    final orderNumber =
        'ORD${DateTime.now().millisecondsSinceEpoch}';

    final response =
        await _supabase
            .from('orders')
            .insert({
              'order_number': orderNumber,
              'user_id':
                  _supabase.auth.currentUser?.id,
              'total_amount': total,
              'order_status': 'pending',
              'payment_status': 'paid',
              'payment_method': 'qris',
              'table_number':
                  note.contains('Meja')
                      ? note.replaceAll(
                          'Meja ',
                          '',
                        )
                      : null,
            })
            .select();

    final orderId = response.first['id'];

    for (final item in items) {
      await _supabase
          .from('order_items')
          .insert({
            'order_id': orderId,
            'menu_id': item['menu_id'],
            'quantity': item['quantity'],
            'price': item['price'],
            'subtotal': item['subtotal'],
          });
    }
  }
}
