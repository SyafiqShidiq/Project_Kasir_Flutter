import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_model.dart';
import '../services/menu_service.dart';
import '../models/product_draft.dart';
import 'menu_filter_provider.dart';

final menuServiceProvider =
    Provider<MenuService>(
  (ref) => MenuService(),
);

final menuProvider =
    AsyncNotifierProvider<
        MenuController,
        List<MenuModel>>(
  MenuController.new,
);

final menuListProvider =
    FutureProvider<List<MenuModel>>(
  (ref) async {
    final menuService =
        ref.read(menuServiceProvider);

    return menuService.getMenus();
  },
);

final availableMenuListProvider =
    FutureProvider<List<MenuModel>>(
  (ref) async {
    final menuService =
        ref.read(menuServiceProvider);

    return menuService.getAvailableMenus();
  },
);
final filteredMenuListProvider =
    Provider<AsyncValue<List<MenuModel>>>(
  (ref) {
    return ref.watch(menuListProvider);
  },
);

final filteredMenusProvider = Provider<List<MenuModel>>((ref) {
  final menusAsync = ref.watch(menuListProvider);
  final filter = ref.watch(menuFilterProvider);

  final menus = menusAsync.value ?? [];
  final query = filter.query.trim().toLowerCase();

  return menus.where((menu) {
    final matchesCategory =
        filter.category == MenuFilter.allCategory ||
        menu.category == filter.category;

    final matchesQuery =
        query.isEmpty ||
        menu.name.toLowerCase().contains(query) ||
        menu.category.toLowerCase().contains(query);

    return matchesCategory && matchesQuery;
  }).toList();
});

class MenuController
    extends AsyncNotifier<List<MenuModel>> {

  late final MenuService _service;

  @override
  Future<List<MenuModel>> build() async {
    _service = ref.read(menuServiceProvider);

    return _service.getMenus();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => _service.getMenus(),
    );
  }

  Future<void> add(ProductDraft draft) async {
    await _service.addMenu(
      name: draft.name,
      description: '${draft.category} menu',
      price: draft.price.toDouble(),
      category: draft.category,
    );

    await refresh();
  }

  Future<void> updateMenu(
    String id,
    ProductDraft draft,
  ) async {
    await _service.updateMenu(
      id: id,
      name: draft.name,
      description: '${draft.category} menu',
      price: draft.price.toDouble(),
      category: draft.category,
      isAvailable: true,
    );

    await refresh();
  }

  Future<void> toggleMenuAvailability(
    MenuModel menu,
  ) async {
    await _service.updateAvailability(
      id: menu.id,
      isAvailable: !menu.isAvailable,
    );

    await refresh();
  }
}