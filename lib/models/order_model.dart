import 'package:flutter/material.dart';

enum OrderStatus {
  paid,
  preparing,
  ready,
  pickedUp,
}

extension OrderStatusText on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Picked up';
    }
  }

  int get step {
    switch (this) {
      case OrderStatus.paid:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.pickedUp:
        return 3;
    }
  }
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
  });

  final String id;
  final String orderNumber;
  final String customer;
  final OrderStatus status;
  final int total;
  final Color accent;
  final List<OrderItem> items;
  final String note;

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
    );
  }

  static OrderStatus parseStatus(
    String? status,
  ) {
    switch (status?.toLowerCase()) {
      case 'pending':
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
    return const CashierOrder(
      id: '',
      orderNumber: '',
      customer: '',
      status: OrderStatus.paid,
      total: 0,
      accent: Color(0xFFFFEDB5),
      items: [],
      note: '',
    );
  }
}