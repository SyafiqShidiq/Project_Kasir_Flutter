import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const ProviderScope(child: SmartCashierApp()));
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const CustomerHomeScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => const QrPaymentScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const OrderTrackingScreen(),
    ),
    GoRoute(
      path: '/cashier',
      builder: (context, state) => const CashierDashboardScreen(),
    ),
    GoRoute(
      path: '/order-detail',
      builder: (context, state) => const OrderDetailScreen(),
    ),
  ],
);

class SmartCashierApp extends StatelessWidget {
  const SmartCashierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartCashier',
      debugShowCheckedModeBanner: false,
      theme: SmartCashierTheme.light(),
      routerConfig: _router,
    );
  }
}

class SmartCashierTheme {
  static const primary = Color(0xFFD32F2F);
  static const primaryDark = Color(0xFFAF101A);
  static const background = Color(0xFFF9F9F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEEEEEE);
  static const surfaceVariant = Color(0xFFE2E2E2);
  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF5B403D);
  static const outline = Color(0xFF8F6F6C);
  static const error = Color(0xFFBA1A1A);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primaryDark,
      onPrimary: Colors.white,
      primaryContainer: primary,
      surface: background,
      onSurface: onSurface,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

final productsProvider = Provider<List<Product>>(
  (ref) => const [
    Product(
      id: 'p1',
      name: 'Crispy Chicken Bowl',
      category: 'Meals',
      price: 28000,
      color: Color(0xFFFFD7C2),
      icon: Icons.rice_bowl,
    ),
    Product(
      id: 'p2',
      name: 'Beef Teriyaki',
      category: 'Meals',
      price: 36000,
      color: Color(0xFFDDE8D4),
      icon: Icons.lunch_dining,
    ),
    Product(
      id: 'p3',
      name: 'Iced Matcha Latte',
      category: 'Drinks',
      price: 22000,
      color: Color(0xFFD9F1E2),
      icon: Icons.local_cafe,
    ),
    Product(
      id: 'p4',
      name: 'Berry Soda',
      category: 'Drinks',
      price: 18000,
      color: Color(0xFFFFD5E5),
      icon: Icons.local_drink,
    ),
    Product(
      id: 'p5',
      name: 'French Fries',
      category: 'Snacks',
      price: 17000,
      color: Color(0xFFFFEDB5),
      icon: Icons.fastfood,
    ),
    Product(
      id: 'p6',
      name: 'Chocolate Waffle',
      category: 'Dessert',
      price: 25000,
      color: Color(0xFFE7D4C5),
      icon: Icons.bakery_dining,
    ),
  ],
);

final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState(lines: []);

  void add(Product product) {
    final existing = state.lines.where((line) => line.product.id == product.id);
    if (existing.isEmpty) {
      state = state.copyWith(
        lines: [
          ...state.lines,
          CartLine(product: product, quantity: 1),
        ],
      );
      return;
    }

    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.product.id == product.id)
            line.copyWith(quantity: line.quantity + 1)
          else
            line,
      ],
    );
  }

  void decrease(Product product) {
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.product.id == product.id && line.quantity > 1)
            line.copyWith(quantity: line.quantity - 1)
          else if (line.product.id != product.id)
            line,
      ],
    );
  }

  void clear() {
    state = const CartState(lines: []);
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final Color color;
  final IconData icon;
}

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;
  int get subtotal => product.price * quantity;

  CartLine copyWith({int? quantity}) {
    return CartLine(product: product, quantity: quantity ?? this.quantity);
  }
}

class CartState {
  const CartState({required this.lines});

  final List<CartLine> lines;
  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);
  int get subtotal => lines.fold(0, (total, line) => total + line.subtotal);
  int get tax => (subtotal * 0.1).round();
  int get service => itemCount == 0 ? 0 : 4000;
  int get total => subtotal + tax + service;

  CartState copyWith({List<CartLine>? lines}) {
    return CartState(lines: lines ?? this.lines);
  }
}

extension RupiahFormat on int {
  String get rupiah {
    final text = toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 28),
            const SmartCashierLogo(size: 84),
            const SizedBox(height: 28),
            Text(
              'SmartCashier',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Fast mobile POS for food service teams',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SmartCashierTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 14),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/cashier'),
              icon: const Icon(Icons.login),
              label: const Text('Sign in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Open customer menu'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
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
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
        children: [
          const SearchPanel(),
          const SizedBox(height: 16),
          const CategoryChips(),
          const SizedBox(height: 18),
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
      bottomNavigationBar: const SmartNavigationBar(activeIndex: 0),
    );
  }
}

class CashierDashboardScreen extends ConsumerWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.go('/login'),
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
                  label: 'Active cart',
                  value: '${cart.itemCount}',
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Live orders',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const OrderTile(
            orderId: '#402',
            customer: 'Dina',
            status: 'Preparing',
            total: 'Rp86.000',
            accent: Color(0xFFFFEDB5),
          ),
          const SizedBox(height: 10),
          const OrderTile(
            orderId: '#403',
            customer: 'Rafi',
            status: 'Ready',
            total: 'Rp54.000',
            accent: Color(0xFFD9F1E2),
          ),
          const SizedBox(height: 10),
          const OrderTile(
            orderId: '#404',
            customer: 'Maya',
            status: 'Paid',
            total: 'Rp118.000',
            accent: Color(0xFFFFD5E5),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/'),
        backgroundColor: SmartCashierTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New order'),
      ),
      bottomNavigationBar: const SmartNavigationBar(activeIndex: 3),
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: cart.lines.isEmpty
          ? const EmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 132),
              children: [
                for (final line in cart.lines) ...[
                  CartLineCard(line: line),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                PriceSummary(cart: cart),
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

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

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
          const SectionCard(
            title: 'Customer',
            child: Column(
              children: [
                DetailRow(label: 'Name', value: 'Walk-in Customer'),
                Divider(height: 24),
                DetailRow(label: 'Table', value: 'Take away'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Payment method',
            child: Column(
              children: [
                PaymentOption(
                  icon: Icons.qr_code_2,
                  title: 'QRIS',
                  subtitle: 'Instant scan payment',
                  selected: true,
                ),
                const Divider(height: 24),
                PaymentOption(
                  icon: Icons.payments_outlined,
                  title: 'Cash',
                  subtitle: 'Pay at cashier',
                  selected: false,
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
        label: 'Pay now',
        enabled: cart.itemCount > 0,
        onPressed: () => context.go('/payment'),
      ),
    );
  }
}

class QrPaymentScreen extends ConsumerWidget {
  const QrPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

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
          SectionCard(
            title: 'Scan to pay',
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
                const Text('Order #402 - expires in 04:58'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const OrderProgress(currentStep: 1),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              context.go('/tracking');
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as paid'),
          ),
        ],
      ),
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          OrderHeaderCard(),
          SizedBox(height: 12),
          OrderProgress(currentStep: 2),
          SizedBox(height: 12),
          SectionCard(
            title: 'Pickup details',
            child: Column(
              children: [
                DetailRow(label: 'Order', value: '#402'),
                Divider(height: 24),
                DetailRow(label: 'Counter', value: 'Pickup A'),
                Divider(height: 24),
                DetailRow(label: 'Estimated ready', value: '8 minutes'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SmartNavigationBar(activeIndex: 2),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order #402'),
        leading: IconButton(
          onPressed: () => context.go('/cashier'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          OrderHeaderCard(),
          SizedBox(height: 12),
          SectionCard(
            title: 'Items',
            child: Column(
              children: [
                DetailRow(label: '2x Crispy Chicken Bowl', value: 'Rp56.000'),
                Divider(height: 24),
                DetailRow(label: '1x Iced Matcha Latte', value: 'Rp22.000'),
              ],
            ),
          ),
          SizedBox(height: 12),
          SectionCard(
            title: 'Kitchen notes',
            child: Text('No onion. Extra sauce on the side.'),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: null,
          icon: Icon(Icons.done_all),
          label: Text('Ready for pickup'),
        ),
      ),
    );
  }
}

class ResponsiveProductGrid extends StatelessWidget {
  const ResponsiveProductGrid({super.key, required this.products});

  final List<Product> products;

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
              ProductCard(product: products[index]),
        );
      },
    );
  }
}

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(cartProvider.notifier).add(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                color: product.color,
                child: Icon(
                  product.icon,
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
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      product.category,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: SmartCashierTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.price.rupiah,
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

class SearchPanel extends StatelessWidget {
  const SearchPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(
        hintText: 'Search menu or order code',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = ['All', 'Meals', 'Drinks', 'Snacks', 'Dessert'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            FilterChip(
              selected: category == 'All',
              onSelected: (_) {},
              label: Text(category),
              selectedColor: SmartCashierTheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: category == 'All'
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
            QuantityStepper(line: line),
          ],
        ),
      ),
    );
  }
}

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
            FilledButton(
              onPressed: enabled ? onPressed : null,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class SmartNavigationBar extends StatelessWidget {
  const SmartNavigationBar({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: activeIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
          case 1:
            context.go('/cart');
          case 2:
            context.go('/tracking');
          case 3:
            context.go('/cashier');
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
        NavigationDestination(
          icon: Icon(Icons.route_outlined),
          selectedIcon: Icon(Icons.route),
          label: 'Track',
        ),
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Cashier',
        ),
      ],
    );
  }
}

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

class OrderTile extends StatelessWidget {
  const OrderTile({
    super.key,
    required this.orderId,
    required this.customer,
    required this.status,
    required this.total,
    required this.accent,
  });

  final String orderId;
  final String customer;
  final String status;
  final String total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.go('/order-detail'),
        leading: CircleAvatar(
          backgroundColor: accent,
          foregroundColor: SmartCashierTheme.primaryDark,
          child: const Icon(Icons.receipt_long),
        ),
        title: Text('$orderId - $customer'),
        subtitle: Text(status),
        trailing: Text(
          total,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

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

class PaymentOption extends StatelessWidget {
  const PaymentOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: selected
              ? SmartCashierTheme.primary
              : SmartCashierTheme.surfaceVariant,
          foregroundColor: selected
              ? Colors.white
              : SmartCashierTheme.onSurface,
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SmartCashierTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected
              ? SmartCashierTheme.primary
              : SmartCashierTheme.outline,
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
  const OrderHeaderCard({super.key});

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
                    'Order #402',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Preparing - paid with QRIS',
                    style: TextStyle(color: Colors.white),
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

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Add menu items to start a new order.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse menu'),
            ),
          ],
        ),
      ),
    );
  }
}
