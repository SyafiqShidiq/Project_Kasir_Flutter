import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> createQris({
    required String orderId,
    required int grossAmount,
  }) async {
    final response = await _client.functions.invoke(
      'create-qris',
      body: {
        'order_id': orderId,
        'gross_amount': grossAmount,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
  Future<Map<String, dynamic>> checkPayment(
      String orderId,
  ) async {

    final response = await _client.functions.invoke(
      'check-payment',
      body: {
        'order_id': orderId,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }
}