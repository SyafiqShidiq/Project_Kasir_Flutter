import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_info.dart';

class CustomerInfoController
    extends Notifier<CustomerInfo> {

  @override
  CustomerInfo build() => const CustomerInfo();

  void update({
    required String name,
    required String table,
  }) {
    state = CustomerInfo(
      name: name,
      table: table,
    );
  }

  void clear() {
    state = const CustomerInfo();
  }
}

final customerInfoProvider =
    NotifierProvider<
      CustomerInfoController,
      CustomerInfo
    >(
      CustomerInfoController.new,
    );