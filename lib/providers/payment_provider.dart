import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentMethod {
  qris,
  cash,
}

class PaymentMethodController extends Notifier<PaymentMethod> {
  @override
  PaymentMethod build() => PaymentMethod.qris;

  void select(PaymentMethod method) {
    state = method;
  }
}

final paymentMethodProvider =
    NotifierProvider<PaymentMethodController, PaymentMethod>(
  PaymentMethodController.new,
);