import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_model.dart';
import '../services/menu_service.dart';

final menuServiceProvider =
    Provider<MenuService>(
  (ref) => MenuService(),
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