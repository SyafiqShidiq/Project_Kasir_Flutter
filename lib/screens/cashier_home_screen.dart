import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../extensions/app_extensions.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart' as order_model;
import '../models/product_draft.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';
import '../theme/smart_cashier_theme.dart';
import 'shared_widgets.dart';

// ==================== CASHIER HOME SCREEN ====================
class CashierHomeScreen extends ConsumerWidget {
  const CashierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider).value ?? [];
    final products = ref.watch(menuProvider).value ?? [];
    final activeProducts = products.where((item) => item.isAvailable).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).logout();
                if (context.mounted) {
                  context.go('/');
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout gagal: $error')),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Today sales',
                  value: 2450000.rupiah,
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: MetricCard(
                  label: 'Orders',
                  value: '48',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: MetricCard(
                  label: 'Queue',
                  value: '7',
                  icon: Icons.hourglass_top,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'Menu aktif',
                  value: '$activeProducts',
                  icon: Icons.restaurant_menu_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CashierMenuShortcut(
            totalMenu: products.length,
            activeMenu: activeProducts,
          ),
          const SizedBox(height: 20),
          Text(
            'Live orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final order in orders) ...[
            OrderTile(order: order),
            const SizedBox(height: 10),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    // Refresh produk
    await ref.read(menuProvider.notifier).refresh();
    // Refresh order
    await ref.read(orderProvider.notifier).refresh();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil direfresh!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  },
  backgroundColor: SmartCashierTheme.primary,
  foregroundColor: Colors.white,
  icon: const Icon(Icons.refresh),
  label: const Text('Refresh'),
),
      bottomNavigationBar: const CashierNavigationBar(activeIndex: 0),
    );
  }
}

// ==================== CASHIER NAVIGATION BAR ====================
class CashierNavigationBar extends StatelessWidget {
  const CashierNavigationBar({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: activeIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/cashier');
          case 1:
            context.go('/cashier/menu');
          case 2:
            context.go('/order-detail');
          case 3:
            context.go('/report');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(
            Icons.bar_chart,
            color: SmartCashierTheme.primary,
          ),
          label: 'Laporan',
        ),
      ],
    );
  }
}

// ==================== CASHIER MENU SCREEN ====================
class CashierMenuScreen extends ConsumerWidget {
  const CashierMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);

    return menuAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),

      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            'Error: $error',
          ),
        ),
      ),

      data: (allMenus) {
        final inactive =
            allMenus
                .where(
                  (menu) => !menu.isAvailable,
                )
                .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kelola Menu'),
            actions: [
              IconButton(
                tooltip: 'Tambah menu',
                onPressed: () => showMenuEditorSheet(context, ref),
                icon: const Icon(Icons.add_circle_outline),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 108),
            children: [
              CashierMenuHero(
                totalMenu: allMenus.length,
                activeMenu: allMenus.where((item) => item.isAvailable).length,
                inactive: inactive,
              ),
              const SizedBox(height: 16),
              const SearchPanel(),
              const SizedBox(height: 14),
              const CategoryChips(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daftar menu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showMenuEditorSheet(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (allMenus.isEmpty)
                const EmptyMenuResult()
              else
                for (final menu in allMenus) ...[
                  CashierMenuTile(menu: menu),
                  const SizedBox(height: 12),
                ],
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showMenuEditorSheet(context, ref),
            backgroundColor: SmartCashierTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Menu baru'),
          ),
          bottomNavigationBar: const CashierNavigationBar(activeIndex: 1),
        );
      },
    );
  }
}

// ==================== CASHIER MENU SHORTCUT ====================
class CashierMenuShortcut extends StatelessWidget {
  const CashierMenuShortcut({
    super.key,
    required this.totalMenu,
    required this.activeMenu,
  });

  final int totalMenu;
  final int activeMenu;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/cashier/menu'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: SmartCashierTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: SmartCashierTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola menu kasir',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeMenu aktif dari $totalMenu menu',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SmartCashierTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CASHIER MENU HERO ====================
class CashierMenuHero extends StatelessWidget {
  const CashierMenuHero({
    super.key,
    required this.totalMenu,
    required this.activeMenu,
    required this.inactive,
  });

  final int totalMenu;
  final int activeMenu;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SmartCashierTheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SmartCashierTheme.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Menu kasir',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Atur ketersediaan dan harga menu.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MenuHeroMetric(label: 'Total', value: '$totalMenu'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MenuHeroMetric(label: 'Aktif', value: '$activeMenu'),
              ),
            ],
          ),
          if (inactive > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$inactive menu sedang dinonaktifkan',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== MENU HERO METRIC ====================
class MenuHeroMetric extends StatelessWidget {
  const MenuHeroMetric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CASHIER MENU TILE ====================
class CashierMenuTile extends ConsumerWidget {
  const CashierMenuTile({super.key, required this.menu});

  final MenuModel menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = menu.isAvailable
        ? Colors.green.shade700
        : SmartCashierTheme.outline;
    final statusText = menu.isAvailable ? 'Tersedia' : 'Nonaktif';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F1E2),
                  image: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(menu.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (menu.imageUrl == null || menu.imageUrl!.isEmpty)
                    ? const Icon(
                        Icons.restaurant_menu,
                        color: SmartCashierTheme.primaryDark,
                        size: 30,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${menu.category} • ${menu.price.toInt().rupiah}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SmartCashierTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MenuStatusChip(label: statusText, color: statusColor),
                ],
              ),
            ),
            // Toggle button
            Switch(
              value: menu.isAvailable,
              activeColor: Colors.green,
              onChanged: (value) async {
                try {
                  await ref
                      .read(menuProvider.notifier)
                      .toggleMenuAvailability(menu);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal mengubah status menu: $e',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            // Edit menu
            IconButton(
              tooltip: 'Edit menu',
              onPressed: () => showMenuEditorSheet(
                context,
                ref,
                menu: menu,
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MENU STATUS CHIP ====================
class MenuStatusChip extends StatelessWidget {
  const MenuStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ==================== MENU EDITOR SHEET ====================
Future<void> showMenuEditorSheet(
  BuildContext context,
  WidgetRef _, {
  MenuModel? menu,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MenuEditorSheet(menu: menu),
  );
}

class MenuEditorSheet extends ConsumerStatefulWidget {
  const MenuEditorSheet({super.key, this.menu});

  final MenuModel? menu;

  @override
  ConsumerState<MenuEditorSheet> createState() => _MenuEditorSheetState();
}

class _MenuEditorSheetState extends ConsumerState<MenuEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late String _category;
  late IconData _icon;
  late Color _color;

  static const _categories = ['Meals', 'Drinks', 'Snacks', 'Dessert'];
  static const _icons = [
    Icons.rice_bowl,
    Icons.lunch_dining,
    Icons.local_cafe,
    Icons.local_drink,
    Icons.fastfood,
    Icons.bakery_dining,
  ];
  static const _colors = [
    Color(0xFFFFD7C2),
    Color(0xFFDDE8D4),
    Color(0xFFD9F1E2),
    Color(0xFFFFD5E5),
    Color(0xFFFFEDB5),
    Color(0xFFE7D4C5),
  ];

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _nameController = TextEditingController(text: menu?.name ?? '');
    _priceController = TextEditingController(
      text: menu == null ? '' : '${menu.price}',
    );
    _imageUrlController = TextEditingController(
      text: menu?.imageUrl ?? '',
    );
    _category = menu?.category ?? _categories.first;
    _icon = _icons.first;
    _color = _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: SmartCashierTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: SmartCashierTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.menu == null ? 'Tambah menu baru' : 'Edit menu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lengkapi nama, kategori, dan harga menu.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: SmartCashierTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nama menu',
              prefixIcon: Icon(Icons.restaurant_menu),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: 'URL Gambar (opsional)',
              prefixIcon: Icon(Icons.image_outlined),
              hintText: 'https://...',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final category in _categories)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 16),
          Text(
            'Tampilan kartu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in _colors)
                ChoiceChip(
                  selected: _color == color,
                  onSelected: (_) => setState(() => _color = color),
                  label: const SizedBox(width: 28, height: 20),
                  avatar: CircleAvatar(backgroundColor: color),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final icon in _icons)
                ChoiceChip(
                  selected: _icon == icon,
                  onSelected: (_) => setState(() => _icon = icon),
                  label: Icon(icon, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              widget.menu == null ? 'Simpan menu' : 'Simpan perubahan',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price =
        double.tryParse(
          _priceController.text.trim(),
        ) ??
        0;
    final imageUrl =
        _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim();

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nama dan harga menu wajib diisi.',
          ),
        ),
      );
      return;
    }

    try {
      final controller =
          ref.read(menuProvider.notifier);

      if (widget.menu == null) {
        await controller.add(
          MenuDraft(
            name: name,
            price: price.toInt(),
            category: _category,
            color: _color,
            icon: _icon,
            imageUrl: imageUrl,
          ),
        );
      } else {
        await controller.updateMenu(
          widget.menu!.id,
          MenuDraft(
            name: name,
            price: price.toInt(),
            category: _category,
            color: _color,
            icon: _icon,
            imageUrl: imageUrl,
          ),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.menu == null
                ? 'Menu berhasil ditambahkan'
                : 'Menu berhasil diperbarui',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menambah menu: $e',
          ),
        ),
      );
    }
  }
}

// ==================== METRIC CARD ====================
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SmartCashierTheme.primary),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: SmartCashierTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ORDER TILE ====================
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order});

  final order_model.CashierOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.go('/order-detail'),
        leading: CircleAvatar(
          backgroundColor: order.accent,
          foregroundColor: SmartCashierTheme.primaryDark,
          child: const Icon(Icons.receipt_long),
        ),
        title: Text('${order.orderNumber} - ${order.customer}'),
        subtitle: Text(order.status.label),
        trailing: Text(
          order.total.rupiah,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider).value ?? [];
    
    if (orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Detail'),
          leading: IconButton(
            onPressed: () => context.go('/cashier'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: Text('Tidak ada order')),
      );
    }

    final order = orders.first;
    final isReady = order.status == order_model.OrderStatus.ready;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.orderNumber}'),
        leading: IconButton(
          onPressed: () => context.go('/cashier'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OrderHeaderCard(order: order),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Items',
            child: Column(
              children: [
                for (var i = 0; i < order.items.length; i++) ...[
                  DetailRow(
                    label: '${order.items[i].quantity}x ${order.items[i].name}',
                    value: order.items[i].subtotal.rupiah,
                  ),
                  if (i != order.items.length - 1) const Divider(height: 24),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(title: 'Catatan', child: Text(order.note)),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: isReady
              ? null
              : () {
                  ref.read(orderProvider.notifier).markOrderReady(order.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${order.orderNumber} siap diambil')),
                  );
                },
          icon: const Icon(Icons.done_all),
          label: Text(isReady ? 'Sudah siap' : 'Tandai siap'),
        ),
      ),
    );
  }
}