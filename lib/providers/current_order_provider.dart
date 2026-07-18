import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentOrderProvider =
    NotifierProvider<CurrentOrderNotifier, Map<String, dynamic>?>(
  CurrentOrderNotifier.new,
);

class CurrentOrderNotifier
    extends Notifier<Map<String, dynamic>?> {

  @override
  Map<String, dynamic>? build() {
    return null;
  }

  void setOrder(Map<String, dynamic> order) {
    print(
      'CurrentOrderProvider SET -> ${order['order_number']}',
    );
    state = order;
  }

  void clear() {
    print('CurrentOrderProvider CLEAR');
    state = null;
  }
}