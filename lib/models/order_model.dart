import 'package:flutter/material.dart';

enum OrderStatus {
  waitingPayment,
  paid,
  preparing,
  ready,
  pickedUp,
}

class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.subtotal,
  });

  final String name;
  final int quantity;
  final int subtotal;
}

class CashierOrder {
  const CashierOrder({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.status,
    required this.total,
    required this.accent,
    required this.items,
    required this.note,
    required this.createdAt,
  });
  factory CashierOrder.fromOrderJson({
    required Map<String, dynamic> orderJson,
    required List<OrderItem> items,
  }) {
    final table = orderJson['table_number'];

    return CashierOrder(
      id: orderJson['id'] ?? '',
      orderNumber: orderJson['order_number'] ?? '',
      customer: orderJson['customer_name'] ?? 'Customer',
      status: CashierOrder.parseStatus(
        orderJson['order_status'],
      ),
      total: (orderJson['total_amount'] as num?)?.toInt() ?? 0,
      accent: _statusColor(
        orderJson['order_status'],
      ),
      items: items,
      note: table == null
          ? 'Take Away'
          : 'Meja $table',
      createdAt: DateTime.parse(orderJson['created_at']).toLocal(),
    );
  }

  final String id;
  final String orderNumber;
  final String customer;
  final OrderStatus status;
  final int total;
  final Color accent;
  final List<OrderItem> items;
  final String note;
  final DateTime createdAt;

  CashierOrder copyWith({
    OrderStatus? status,
  }) {
    return CashierOrder(
      id: id,
      orderNumber: orderNumber,
      customer: customer,
      status: status ?? this.status,
      total: total,
      accent: accent,
      items: items,
      note: note,
      createdAt: createdAt,
    );
  }

  static OrderStatus parseStatus(
    String? status,
  ) {
    switch (status?.toLowerCase()) {
      case 'waiting_payment':
        return OrderStatus.waitingPayment;
      case 'paid':
        return OrderStatus.paid;

      case 'preparing':
        return OrderStatus.preparing;

      case 'ready':
        return OrderStatus.ready;

      case 'completed':
        return OrderStatus.pickedUp;

      default:
        return OrderStatus.paid;
    }
  }

  static CashierOrder empty() {
    return CashierOrder(
      id: '',
      orderNumber: '',
      customer: '',
      status: OrderStatus.paid,
      total: 0,
      accent: Color(0xFFFFEDB5),
      items: [],
      note: '',
      createdAt: DateTime.now(),
    );
  }
  static Color _statusColor(
    String? status,
  ) {
    switch (status) {
      case 'waiting_payment':
        return const Color(0xFFFFD5E5);
      case 'paid':
        return const Color(0xFFFFD5E5);

      case 'preparing':
        return const Color(0xFFFFEDB5);

      case 'ready':
        return const Color(0xFFD9F1E2);

      case 'completed':
        return const Color(0xFFE7D4C5);

      default:
        return const Color(0xFFFFEDB5);
    }
  }
}