import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/app_config.dart';

final updateServiceProvider = Provider<UpdateService>(
  (ref) => UpdateService(
    Supabase.instance.client,
  ),
);

class UpdateService {
  UpdateService(this._supabase);

  final SupabaseClient _supabase;

  Future<AppConfig> getConfig() async {
    final data = await _supabase
        .from('app_config')
        .select()
        .single();

    return AppConfig.fromJson(data);
  }
}