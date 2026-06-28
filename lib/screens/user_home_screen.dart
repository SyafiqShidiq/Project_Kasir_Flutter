import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_kasir_flutter/models/menu_model.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../models/cart_model.dart';
import '../models/menu_model.dart';
import '../extensions/menu_ui_extension.dart';
import '../providers/menu_provider.dart';
import '../providers/menu_filter_provider.dart';

// ==================== USER HOME SCREEN ====================
class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => _showLogoutDialog(context, ref),
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
                await _handleLogout(context, ref);
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

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      ref.read(cartProvider.notifier).clear();

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
            childAspectRatio: 0.72,
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
                color: menu.color,
                child: Icon(
                  menu.icon,
                  color: SmartCashierTheme.primaryDark,
                  size: 42,
                ),
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
                    const Spacer(),
                    Text(
                      menu.category,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: SmartCashierTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            menu.price.toInt().rupiah,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SEARCH PANEL ====================
class SearchPanel extends ConsumerWidget {
  const SearchPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (value) => ref.read(menuFilterProvider.notifier).search(value),
      decoration: const InputDecoration(
        hintText: 'Search menu or order code',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

// ==================== CATEGORY CHIPS ====================
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(menuFilterProvider).category;
    const categories = ['All', 'Meals', 'Drinks', 'Snacks', 'Dessert'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            FilterChip(
              selected: category == selectedCategory,
              onSelected: (_) => ref
                  .read(menuFilterProvider.notifier)
                  .selectCategory(category),
              label: Text(category),
              selectedColor: SmartCashierTheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: category == selectedCategory
                    ? Colors.white
                    : SmartCashierTheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

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
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

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
          ? const EmptyCartWithMenu()
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
        onPressed: () => context.go('/checkout'),
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
  late TextEditingController _tableController;

  @override
  void initState() {
    super.initState();
    final customerInfo = ref.read(customerInfoProvider);
    _tableController = TextEditingController(text: customerInfo.table);
  }

  @override
  void dispose() {
    _tableController.dispose();
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
                TextField(
                  key: const Key('checkout_table_field'),
                  controller: _tableController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Meja',
                    prefixIcon: Icon(Icons.table_restaurant),
                    hintText: 'e.g., 5 (kosongkan untuk Take away)',
                    border: OutlineInputBorder(),
                  ),
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
        onPressed: () {
          // Save table info, name auto from profile
          final table = _tableController.text;
          ref.read(customerInfoProvider.notifier).update(
            name: customerName, // Auto dari profil user yang login
            table: table,
          );

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
    final cart = ref.watch(cartProvider);
    final customerInfo = ref.watch(customerInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Payment'),
        leading: IconButton(
          onPressed: () => context.go('/checkout'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                      customerInfo.name.isNotEmpty 
                        ? customerInfo.name[0].toUpperCase() 
                        : 'C',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan atas nama ${customerInfo.name}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (customerInfo.table.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Meja ${customerInfo.table}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SmartCashierTheme.onSurfaceVariant,
                            ),
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
                  child: const QrMark(),
                ),
                const SizedBox(height: 20),
                Text(
                  cart.total.rupiah,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Scan kode QR untuk menyelesaikan pembayaran'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const OrderProgress(currentStep: 0),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Create order with customer name from profile
              final name = customerInfo.name.isNotEmpty 
                ? customerInfo.name 
                : 'Customer';
              final table = customerInfo.table;
              
              ref.read(cashierOrdersProvider.notifier).addOrder(
                customer: name,
                note: table.isEmpty ? 'Take away' : 'Meja $table',
                cart: cart,
              );

              ref.read(cartProvider.notifier).clear();
              ref.read(customerInfoProvider.notifier).clear();
              context.go('/user-home');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pesanan atas nama $name berhasil dibuat!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Konfirmasi Pembayaran'),
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

  final CashierOrder order;

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