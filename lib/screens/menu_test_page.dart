import 'package:flutter/material.dart';

import '../services/menu_service.dart';

class MenuTestPage extends StatefulWidget {
  const MenuTestPage({super.key});

  @override
  State<MenuTestPage> createState() =>
      _MenuTestPageState();
}

class _MenuTestPageState
    extends State<MenuTestPage> {

  @override
  void initState() {
    super.initState();
    _testMenu();
  }

  Future<void> _testMenu() async {
    try {
      final menuService = MenuService();

      final menus =
          await menuService.getMenus();

      debugPrint(
        'Jumlah menu: ${menus.length}',
      );

      for (final menu in menus) {
        debugPrint(menu.toString());
      }
    } catch (e) {
      debugPrint(
        'ERROR MENU: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Menu Test Page',
        ),
      ),
    );
  }
}