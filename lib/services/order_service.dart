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
          .select('''
            quantity,
            subtotal,
            menus(name)
          ''')
          .eq(
            'order_id',
            orderJson['id'],
          );

      final items =
          itemsData
              .map<OrderItem>(
                (item) => OrderItem(
                  name: item['menus']['name'] ?? '',
                  quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                  subtotal: (item['subtotal'] as num?)?.toInt() ?? 0,
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
  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    final data = await _supabase
        .from('orders')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .neq('order_status', 'completed')
        .order(
          'created_at',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(data);
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
  Future<void> savePaymentData({
    required String orderId,
    required String paymentUrl,
    required String qrUrl,
    required String midtransOrderId,
  }) async {
    await _supabase
        .from('orders')
        .update({
          'payment_url': paymentUrl,
          'qr_url': qrUrl,
          'midtrans_order_id': midtransOrderId,
        })
        .eq(
          'id',
          orderId,
        );
  }

  Future<Map<String, dynamic>> addOrder({
    required String customer,
    required String orderType,
    int? tableNumber,
    required int total,
    required List<Map<String, dynamic>> items,
  }) async {

    final response =
        await _supabase.from('orders').insert({
              'user_id': _supabase.auth.currentUser?.id,
              'customer_name': customer,
              'total_amount': total,
              'order_status': 'waiting_payment',
              'payment_status': 'unpaid',
              'payment_method': 'qris',
              'order_type': orderType,
              'table_number': tableNumber,
            }).select();

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
    return response.first;
  }
}
