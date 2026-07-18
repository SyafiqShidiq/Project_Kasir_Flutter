import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_kasir_flutter/models/menu_model.dart';
import 'package:project_kasir_flutter/models/qr_payload.dart';

import '../extensions/app_extensions.dart';
import '../extensions/menu_ui_extension.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart' as order_model;
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';
import '../providers/current_order_provider.dart';
import '../providers/merchant_provider.dart';
import '../theme/smart_cashier_theme.dart';
import 'shared_widgets.dart';

// ==================== USER HOME SCREEN ====================
class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() =>
      _UserHomeScreenState();
}
class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref
          .read(orderProvider.notifier)
          .restoreCurrentOrder();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredMenusProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          Badge(
            label: Text('${cart.itemCount}'),
            isLabelVisible: cart.itemCount > 0,
            child: IconButton(
              onPressed: () => context.go('/cart'),
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
        children: [
          const SearchPanel(),
          const SizedBox(height: 16),
          const CategoryChips(),
          const SizedBox(height: 18),
          if (products.isEmpty)
            const EmptyMenuResult()
          else
            ResponsiveProductGrid(products: products),
        ],
      ),
      floatingActionButton: cart.itemCount == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go('/cart'),
              backgroundColor: SmartCashierTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.receipt_long),
              label: Text('${cart.itemCount} items'),
            ),
      bottomNavigationBar: const CustomerNavigationBar(activeIndex: 0),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleLogout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      ref.read(cartProvider.notifier).clear();
      ref.read(currentOrderProvider.notifier).clear();

      await ref.read(authServiceProvider).logout();

      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(userRoleProvider);
      ref.invalidate(isLoggedInProvider);

      if (!context.mounted) return;

      context.go('/');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// ==================== CUSTOMER NAVIGATION BAR ====================
class CustomerNavigationBar extends StatelessWidget {
  const CustomerNavigationBar({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: activeIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/user-home');
          case 1:
            context.go('/cart');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
      ],
    );
  }
}

// ==================== PRODUCT GRID ====================
class ResponsiveProductGrid extends StatelessWidget {
  const ResponsiveProductGrid({super.key, required this.products});

  final List<MenuModel> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 280,
          ),
          itemBuilder: (context, index) =>
              MenuCard(menu: products[index]),
        );
      },
    );
  }
}

// ==================== PRODUCT CARD ====================
class MenuCard extends ConsumerWidget {
  const MenuCard({super.key, required this.menu});

  final MenuModel menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(cartProvider.notifier).add(menu),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: menu.color,
                  image: menu.imageUrl != null && menu.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(menu.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (menu.imageUrl == null || menu.imageUrl!.isEmpty)
                    ? Icon(
                        menu.icon,
                        color: SmartCashierTheme.primaryDark,
                        size: 42,
                      )
                    : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      menu.category,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: SmartCashierTheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            menu.price.toInt().rupiah,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: SmartCashierTheme.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const CircleAvatar(
                          radius: 17,
                          backgroundColor: SmartCashierTheme.primary,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SEARCH PANEL ====================

// ==================== CATEGORY CHIPS ====================


// ==================== EMPTY MENU RESULT ====================
class EmptyMenuResult extends StatelessWidget {
  const EmptyMenuResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 44,
              color: SmartCashierTheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Menu not found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Try another keyword or category.'),
          ],
        ),
      ),
    );
  }
}

// ==================== CART SCREEN ====================
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() =>
      _CartScreenState();
}
class _CartScreenState extends ConsumerState<CartScreen> {
  Future<void> _loadCurrentOrder() async {
    final order = await ref
        .read(orderProvider.notifier)
        .loadActiveOrder();

    if (order != null) {
      ref
          .read(currentOrderProvider.notifier)
          .setOrder(order);
    } else {
      ref
          .read(currentOrderProvider.notifier)
          .clear();
    }
  }
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await _loadCurrentOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final currentOrder = ref.watch(currentOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          onPressed: () => context.go('/user-home'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (cart.itemCount > 0)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.lines.isEmpty
          ? currentOrder == null
              ? const EmptyCartWithMenu()
              : EmptyCartWithInvoice(
                  order: currentOrder,
                )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 132),
              children: [
                Text(
                  'Your order',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final line in cart.lines) ...[
                  CartLineCard(line: line),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                PriceSummary(cart: cart),
                const SizedBox(height: 18),
                const CartMenuPicker(title: 'Add more menu'),
              ],
            ),
      bottomNavigationBar: CheckoutBar(
        total: cart.total,
        label: 'Checkout',
        enabled: cart.itemCount > 0,
        onPressed: () async {
  if (currentOrder != null &&
      currentOrder['payment_status'] == 'unpaid') {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Masih Ada Pesanan Aktif'),
          content: const Text(
            'Selesaikan pembayaran pesanan sebelumnya terlebih dahulu sebelum membuat pesanan baru.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Tutup'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Lihat Status Pesanan'),
                    ),
                  ],
                );
              },
            );

            if (result == true && context.mounted) {
              context.go('/payment');
            }

            return;
          }

          context.go('/checkout');
        },
      ),
    );
  }
}

// ==================== CART LINE CARD ====================
class CartLineCard extends ConsumerWidget {
  const CartLineCard({super.key, required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: line.product.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                line.product.icon,
                color: SmartCashierTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(line.subtotal.rupiah),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuantityStepper(line: line),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(cartProvider.notifier).remove(line.product),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== QUANTITY STEPPER ====================
class QuantityStepper extends ConsumerWidget {
  const QuantityStepper({super.key, required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: () =>
              ref.read(cartProvider.notifier).decrease(line.product),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '${line.quantity}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filled(
          onPressed: () => ref.read(cartProvider.notifier).add(line.product),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

// ==================== PRICE SUMMARY ====================
class PriceSummary extends StatelessWidget {
  const PriceSummary({super.key, required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Summary',
      child: Column(
        children: [
          DetailRow(label: 'Subtotal', value: cart.subtotal.rupiah),
          const SizedBox(height: 10),
          DetailRow(label: 'Tax 10%', value: cart.tax.rupiah),
          const SizedBox(height: 10),
          DetailRow(label: 'Service', value: cart.service.rupiah),
          const Divider(height: 28),
          DetailRow(label: 'Total', value: cart.total.rupiah, strong: true),
        ],
      ),
    );
  }
}

// ==================== CHECKOUT BAR ====================
class CheckoutBar extends StatelessWidget {
  const CheckoutBar({
    super.key,
    required this.total,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final int total;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: SmartCashierTheme.surface,
        border: Border(
          top: BorderSide(color: SmartCashierTheme.surfaceVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total'),
                  Text(
                    total.rupiah,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 132,
              child: FilledButton(
                onPressed: enabled ? onPressed : null,
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EMPTY CART WITH MENU ====================
class EmptyCartWithMenu extends StatelessWidget {
  const EmptyCartWithMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 132),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SmartCashierLogo(size: 72),
                const SizedBox(height: 18),
                Text(
                  'Cart is empty',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tambahkan menu langsung dari cart.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/user-home'),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Browse menu'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const CartMenuPicker(title: 'Tambah menu ke cart'),
      ],
    );
  }
}
class EmptyCartWithInvoice extends StatelessWidget {
  const EmptyCartWithInvoice({
    super.key,
    required this.order,
  });

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    print(
      'ActiveInvoiceCard build -> ${order['order_number']}',
    );
    final isTakeAway =
        order['order_type'] == 'take_away';

    final paymentStatus =
        order['payment_status'];

    final paymentLabel =
        paymentStatus == 'paid'
            ? 'Pembayaran Berhasil'
            : 'Menunggu Pembayaran';

    final paymentColor =
        paymentStatus == 'paid'
            ? Colors.green
            : Colors.orange;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        24,
        16,
        132,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Aktif',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                ),

                const SizedBox(height: 16),

                Text(
                  order['order_number'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: paymentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(paymentLabel),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  isTakeAway
                      ? 'Take Away'
                      : 'Meja ${order['table_number']}',
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: () {
                    context.go('/payment');
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text(
                    'Lihat Status Pesanan',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        const CartMenuPicker(
          title: 'Tambah menu ke cart',
        ),
      ],
    );
  }
}

// ==================== CART MENU PICKER ====================
class CartMenuPicker extends ConsumerWidget {
  const CartMenuPicker({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredMenusProvider);

    return SectionCard(
      title: title,
      child: Column(
        children: [
          for (final product in products) ...[
            SuggestedMenuTile(menu: product),
            if (product != products.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

// ==================== SUGGESTED PRODUCT TILE ====================
class SuggestedMenuTile extends ConsumerWidget {
  const SuggestedMenuTile({super.key, required this.menu});

  final MenuModel menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: menu.color,
        foregroundColor: SmartCashierTheme.primaryDark,
        child: Icon(menu.icon),
      ),
      title: Text(menu.name),
      subtitle: Text('${menu.category} - ${menu.price.toInt().rupiah}'),
      trailing: IconButton.filled(
        tooltip: 'Tambah ${menu.name}',
        onPressed: () => ref.read(cartProvider.notifier).add(menu),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// ==================== CHECKOUT SCREEN (AUTO NAME FROM PROFILE) ====================
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _orderType = 'take_away';
  int? _selectedTable;

  @override
  void initState() {
    super.initState();
    final customerInfo = ref.read(customerInfoProvider);
    _selectedTable = int.tryParse(customerInfo.table);
    if (_selectedTable != null) {
      _orderType = 'dine_in';
    } else {
      _orderType = 'take_away';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final userProfile = ref.watch(currentUserProvider);
    
    // Auto-fill name from logged in user profile
    final customerName = userProfile.value?.username ?? 'Customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          onPressed: () => context.go('/cart'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 132),
        children: [
          SectionCard(
            title: 'Customer',
            child: Column(
              children: [
                // Show logged in user info (read-only)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SmartCashierTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SmartCashierTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: SmartCashierTheme.primary,
                        foregroundColor: Colors.white,
                        radius: 22,
                        child: Text(
                          customerName.isNotEmpty 
                            ? customerName[0].toUpperCase() 
                            : 'C',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Memesan sebagai $customerName',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: SmartCashierTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user,
                        color: SmartCashierTheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Table number field
                Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text('Tipe Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Row(
  children: [
    Expanded(
      child: FilledButton(
        onPressed: () {
          setState(() {
            _orderType = 'take_away';
            _selectedTable = null;
          });
        },
        style: FilledButton.styleFrom(
          backgroundColor: _orderType == 'take_away' 
              ? SmartCashierTheme.primary 
              : SmartCashierTheme.surfaceContainer,
          foregroundColor: _orderType == 'take_away' 
              ? Colors.white 
              : SmartCashierTheme.onSurface,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.takeout_dining, size: 18),
            SizedBox(width: 8),
            Text('Take Away'),
          ],
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: FilledButton(
        onPressed: () {
          setState(() {
            _orderType = 'dine_in';
            _selectedTable ??= 1;
          });
        },
        style: FilledButton.styleFrom(
          backgroundColor: _orderType == 'dine_in' 
              ? SmartCashierTheme.primary 
              : SmartCashierTheme.surfaceContainer,
          foregroundColor: _orderType == 'dine_in' 
              ? Colors.white 
              : SmartCashierTheme.onSurface,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 18),
            SizedBox(width: 8),
            Text('Dine In'),
          ],
        ),
      ),
    ),
  ],
),
    if (_orderType == 'dine_in') ...[
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        value: _selectedTable,
        decoration: const InputDecoration(
          labelText: 'Nomor Meja',
          prefixIcon: Icon(Icons.table_restaurant),
          border: OutlineInputBorder(),
        ),
        items: List.generate(
          20,
          (index) => DropdownMenuItem(
            value: index + 1,
            child: Text('Meja ${index + 1}'),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _selectedTable = value;
          });
        },
      )
    ],
  ],
),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Payment method - QRIS only
          SectionCard(
            title: 'Metode Pembayaran',
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SmartCashierTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SmartCashierTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: SmartCashierTheme.primary,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.qr_code_2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QRIS',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Scan & bayar instan',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: SmartCashierTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: SmartCashierTheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pembayaran hanya tersedia melalui QRIS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SmartCashierTheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PriceSummary(cart: cart),
        ],
      ),
      bottomNavigationBar: CheckoutBar(
        total: cart.total,
        label: 'Bayar dengan QRIS',
        enabled: cart.itemCount > 0,
        onPressed: () async {
          // Save table info, name auto from profile
          final table = _selectedTable?.toString() ?? '';
          ref.read(customerInfoProvider.notifier).update(
            name: customerName, // Auto dari profil user yang login
            table: table,
          );
          final createdOrder = await ref.read(orderProvider.notifier).addOrder(
            customer: customerName,
            orderType: _orderType,
            tableNumber: _selectedTable,
            cart: cart,
          );

          ref.read(currentOrderProvider.notifier).setOrder(createdOrder);

          // Go to QR payment screen
          context.go('/payment');
        },
      ),
    );
  }
}

// ==================== QR PAYMENT SCREEN ====================
class QrPaymentScreen extends ConsumerWidget {
  const QrPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrder = ref.watch(currentOrderProvider);
    print(
      'QrPaymentScreen rebuild: ${currentOrder?['order_number']}',
    );
    if (currentOrder == null) {
      return const Scaffold(
        body: Center(
          child: Text('Order tidak ditemukan'),
        ),
      );
    }
    final paymentStatus =
        currentOrder['payment_status'];

    final paymentLabel =
        paymentStatus == 'paid'
            ? 'Pembayaran Berhasil'
            : 'Menunggu Pembayaran';

    final paymentIcon =
        paymentStatus == 'paid'
            ? Icons.check_circle
            : Icons.schedule;

    final paymentColor =
        paymentStatus == 'paid'
            ? Colors.green
            : Colors.orange;
    final isTakeAway = currentOrder['order_type'] == 'take_away';
    final orderTypeLabel =
        isTakeAway ? 'Take Away' : 'Dine In';
    final orderTypeIcon =
        isTakeAway
            ? Icons.takeout_dining
            : Icons.table_restaurant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pesanan'),
        leading: IconButton(
          onPressed: () => context.go('/checkout'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '#${currentOrder['order_number']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        paymentIcon,
                        color: paymentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(paymentLabel),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Customer info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: SmartCashierTheme.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      (currentOrder['customer_name'] as String)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesanan atas nama',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          currentOrder['customer_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(orderTypeIcon, size: 18),
                            const SizedBox(width: 8),
                            Text(orderTypeLabel),
                          ],
                        ),

                        if (!isTakeAway) ...[
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.pin_drop,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text('Meja ${currentOrder['table_number']}'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Scan untuk Bayar',
            child: Column(
              children: [
                Container(
                  width: 228,
                  height: 228,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SmartCashierTheme.surfaceVariant),
                  ),
                  child: Image.asset(
                    'assets/images/qris_saya.jpeg',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'QRIS tidak ditemukan',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  (currentOrder['total_amount'] as num).toInt().rupiah,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total yang harus dibayar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SmartCashierTheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Silakan scan QRIS merchant yang tersedia di meja.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final payload = await context.push<QrPayload>(
                '/qr-scanner',
              );

              if (!context.mounted || payload == null) {
                return;
              }

              if (payload.type != 'merchant') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR bukan Merchant.'),
                  ),
                );
                return;
              }

              final merchantService = ref.read(
                merchantServiceProvider,
              );

              final merchant = await merchantService
                  .getMerchantByCode(payload.value);

              if (!context.mounted) {
                return;
              }

              if (merchant == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Merchant tidak ditemukan atau sudah tidak aktif.',
                    ),
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Merchant "${merchant.merchantName}" berhasil divalidasi.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Merchant'),
          ),
        ],
      ),
    );
  }
}
// ==================== SHARED WIDGETS ====================
// Widgets yang digunakan bersama user dan cashier

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong
                  ? SmartCashierTheme.onSurface
                  : SmartCashierTheme.onSurfaceVariant,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class OrderProgress extends StatelessWidget {
  const OrderProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = ['Paid', 'Preparing', 'Ready', 'Picked up'];
    return SectionCard(
      title: 'Status',
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i <= currentStep
                      ? SmartCashierTheme.primary
                      : SmartCashierTheme.surfaceVariant,
                  foregroundColor: i <= currentStep
                      ? Colors.white
                      : SmartCashierTheme.outline,
                  child: Icon(
                    i <= currentStep ? Icons.check : Icons.circle_outlined,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontWeight: i <= currentStep
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (i != steps.length - 1)
              Container(
                height: 24,
                margin: const EdgeInsets.only(left: 13),
                alignment: Alignment.centerLeft,
                child: const VerticalDivider(
                  color: SmartCashierTheme.surfaceVariant,
                  thickness: 2,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class OrderHeaderCard extends StatelessWidget {
  const OrderHeaderCard({super.key, required this.order});

  final order_model.CashierOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SmartCashierTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: SmartCashierTheme.primary,
              child: Icon(Icons.receipt_long),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${order.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.status.label} - paid with QRIS',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmartCashierLogo extends StatelessWidget {
  const SmartCashierLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: SmartCashierTheme.primary,
          borderRadius: BorderRadius.circular(size * 0.24),
        ),
        child: Icon(
          Icons.point_of_sale,
          color: Colors.white,
          size: size * 0.48,
        ),
      ),
    );
  }
}

class QrMark extends StatelessWidget {
  const QrMark({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 81,
      itemBuilder: (context, index) {
        final filled = index % 2 == 0 || index % 7 == 0 || index == 40;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: filled ? SmartCashierTheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}