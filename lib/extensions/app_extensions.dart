import '../models/app_role.dart';
import '../providers/payment_provider.dart';
import '../models/order_model.dart';


extension AppRoleRoutes on AppRole {
  String get homePath {
    switch (this) {
      case AppRole.user:
        return '/user-home';
      case AppRole.cashier:
        return '/cashier';
    }
  }

  bool canAccess(String path) {
    switch (this) {
      case AppRole.user:
        return const {
          '/user-home',
          '/cart',
          '/checkout',
          '/payment',
        }.contains(path);
      case AppRole.cashier:
        return const {
          '/cashier',
          '/cashier/menu',
          '/order-detail',
        }.contains(path);
    }
  }
}
extension PaymentMethodText on PaymentMethod {
  String get title {
    switch (this) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
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
extension RupiahFormat on int {
  String get rupiah {
    final text = toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }
}