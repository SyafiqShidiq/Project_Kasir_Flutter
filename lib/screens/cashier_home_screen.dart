import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import 'shared_widgets.dart';
import '../providers/auth_provider.dart';

// ==================== CASHIER HOME SCREEN ====================
class CashierHomeScreen extends ConsumerWidget {
  const CashierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(cashierOrdersProvider);
    final products = ref.watch(productsProvider);
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
        onPressed: () {
          ref.read(productsProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil direfresh!')),
          );
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
      ],
    );
  }
}

// ==================== CASHIER MENU SCREEN ====================
class CashierMenuScreen extends ConsumerWidget {
  const CashierMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final allProducts = ref.watch(productsProvider);
    final inactive = allProducts.where((item) => !item.isAvailable).length;

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
            totalMenu: allProducts.length,
            activeMenu: allProducts.where((item) => item.isAvailable).length,
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
          if (products.isEmpty)
            const EmptyMenuResult()
          else
            for (final product in products) ...[
              CashierMenuTile(product: product),
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
  const CashierMenuTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = product.isAvailable
        ? Colors.green.shade700
        : SmartCashierTheme.outline;
    final statusText = product.isAvailable ? 'Tersedia' : 'Nonaktif';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: product.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                product.icon,
                color: SmartCashierTheme.primaryDark,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.category} • ${product.price.rupiah}',
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
              value: product.isAvailable,
              activeColor: Colors.green,
              onChanged: (_) {
                ref
                    .read(productsProvider.notifier)
                    .toggleAvailability(product);
              },
            ),
            // Edit menu
            IconButton(
              tooltip: 'Edit menu',
              onPressed: () => showMenuEditorSheet(context, ref, product: product),
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
  Product? product,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MenuEditorSheet(product: product),
  );
}

class MenuEditorSheet extends ConsumerStatefulWidget {
  const MenuEditorSheet({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<MenuEditorSheet> createState() => _MenuEditorSheetState();
}

class _MenuEditorSheetState extends ConsumerState<MenuEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
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
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : '${product.price}',
    );
    _category = product?.category ?? _categories.first;
    _icon = product?.icon ?? _icons.first;
    _color = product?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
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
            widget.product == null ? 'Tambah menu baru' : 'Edit menu',
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
              widget.product == null ? 'Simpan menu' : 'Simpan perubahan',
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan harga menu wajib diisi.')),
      );
      return;
    }

    final draft = ProductDraft(
      name: name,
      category: _category,
      price: price,
      color: _color,
      icon: _icon,
    );

    final product = widget.product;
    final controller = ref.read(productsProvider.notifier);
    if (product == null) {
      controller.add(draft);
    } else {
      controller.update(product.id, draft);
    }

    Navigator.of(context).pop();
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

  final CashierOrder order;

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
        title: Text('${order.id} - ${order.customer}'),
        subtitle: Text(order.status.label),
        trailing: Text(
          order.total.rupiah,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ==================== ORDER DETAIL SCREEN ====================
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(cashierOrdersProvider).first;
    final isReady = order.status == OrderStatus.ready;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.id}'),
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
          SectionCard(title: 'Kitchen notes', child: Text(order.note)),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: isReady
              ? null
              : () {
                  ref.read(cashierOrdersProvider.notifier).markSelectedReady();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${order.id} is ready for pickup')),
                  );
                },
          icon: const Icon(Icons.done_all),
          label: Text(isReady ? 'Already ready' : 'Ready for pickup'),
        ),
      ),
    );
  }
}