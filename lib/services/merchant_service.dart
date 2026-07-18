import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/merchant_model.dart';

class MerchantService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil merchant berdasarkan merchant_code
  Future<MerchantModel?> getMerchantByCode(String merchantCode) async {
    final response = await _supabase
        .from('merchants')
        .select()
        .eq('merchant_code', merchantCode)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;

    return MerchantModel.fromMap(response);
  }

  /// Mengambil merchant aktif (sementara hanya ada satu merchant)
  Future<MerchantModel?> getCurrentMerchant() async {
    final response = await _supabase
        .from('merchants')
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    print('Merchant Response: $response');

    if (response == null) {
      print('Merchant tidak ditemukan');
      return null;
    }

    return MerchantModel.fromMap(response);
  }

  /// Mengambil merchant berdasarkan UUID
  Future<MerchantModel?> getMerchantById(String id) async {
    final response = await _supabase
        .from('merchants')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return MerchantModel.fromMap(response);
  }
}