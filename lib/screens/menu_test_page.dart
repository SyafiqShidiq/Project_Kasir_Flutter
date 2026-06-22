import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/menu_provider.dart';
import '../models/menu_model.dart';

class MenuTestScreen extends ConsumerWidget {
  const MenuTestScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final menus =
        ref.watch(menuListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu Provider Test',
        ),
      ),
      body: menus.when(
        data: (
          List<MenuModel> data,
        ) {
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Text(
                  'Jumlah menu: ${data.length}',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount:
                      data.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final menu =
                        data[index];

                    return ListTile(
                      title: Text(
                        menu.name,
                      ),
                      subtitle: Text(
                        menu.category,
                      ),
                      trailing: Text(
                        'Rp ${menu.price}',
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },

        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),

        error: (
          error,
          stackTrace,
        ) =>
            Center(
          child: Text(
            'Error: $error',
          ),
        ),
      ),
    );
  }
}