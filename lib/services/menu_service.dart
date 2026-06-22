import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/menu_model.dart';

class MenuService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<MenuModel>> getMenus() async {
    final response = await _supabase
        .from('menus')
        .select()
        .order(
          'created_at',
          ascending: true,
        );
        print(response);
        print('Jumlah raw data: ${response.length}');

    return response
        .map<MenuModel>(
          (json) => MenuModel.fromJson(json),
        )
        .toList();
  }

  Future<List<MenuModel>> getAvailableMenus() async {
    final response = await _supabase
        .from('menus')
        .select()
        .eq(
          'is_available',
          true,
        )
        .order(
          'created_at',
          ascending: true,
        );

    return response
        .map<MenuModel>(
          (json) => MenuModel.fromJson(json),
        )
        .toList();
  }

  Future<void> addMenu({
    required String name,
    String? description,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    await _supabase.from('menus').insert({
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'is_available': true,
    });
  }

  Future<void> updateMenu({
    required String id,
    required String name,
    String? description,
    required double price,
    required String category,
    String? imageUrl,
    required bool isAvailable,
  }) async {
    await _supabase
        .from('menus')
        .update({
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'image_url': imageUrl,
          'is_available': isAvailable,
          'updated_at': DateTime.now()
              .toIso8601String(),
        })
        .eq(
          'id',
          id,
        );
  }

  Future<void> deleteMenu(
    String id,
  ) async {
    await _supabase
        .from('menus')
        .delete()
        .eq(
          'id',
          id,
        );
  }

  Future<void> updateAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    await _supabase
        .from('menus')
        .update({
          'is_available': isAvailable,
          'updated_at': DateTime.now()
              .toIso8601String(),
        })
        .eq(
          'id',
          id,
        );
  }
}