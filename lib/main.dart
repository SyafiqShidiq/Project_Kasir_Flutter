import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'screens/user_home_screen.dart';
import 'screens/cashier_home_screen.dart';
import 'models/app_role.dart';
import '../screens/register_screen.dart';

import '../screens/menu_test_page.dart';

// ==================== MAIN ====================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    const ProviderScope(
      child: SmartCashierApp(),
    ),
  );
}

// ==================== APP ====================
class SmartCashierApp extends ConsumerWidget {
  const SmartCashierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SmartCashier',
      debugShowCheckedModeBanner: false,
      theme: SmartCashierTheme.light(),
      routerConfig: router,
    );
  }
}

// ==================== THEME ====================
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
      splashFactory: InkRipple.splashFactory,
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

// ==================== ROUTER ====================
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Auth Gate
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthGate(),
      ),
      
      // User Routes
      GoRoute(
        path: '/user-home',
        builder: (context, state) => const UserHomeScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const QrPaymentScreen(),
      ),
      
      // Cashier Routes
      GoRoute(
        path: '/cashier',
        builder: (context, state) => const CashierHomeScreen(),
      ),
      GoRoute(
        path: '/cashier/menu',
        builder: (context, state) => const CashierMenuScreen(),
      ),
      GoRoute(
        path: '/order-detail',
        builder: (context, state) => const OrderDetailScreen(),
      ),
    ],
  );
});

// ==================== AUTH CONTROLLER ====================
class AuthController extends Notifier<AppRole?> {
  @override
  AppRole? build() => null;

  void signIn(AppRole role) {
    state = role;
  }

  void signOut() {
    state = null;
  }
}

extension AppRoleRoutes on AppRole {
  String get homePath {
    switch (this) {
      case AppRole.user:
        return '/user-home';
      case AppRole.cashier:
        return '/cashier';
    }
  }

  bool canAccess(String path) {
    switch (this) {
      case AppRole.user:
        return const {
          '/user-home',
          '/cart',
          '/checkout',
          '/payment',
        }.contains(path);
      case AppRole.cashier:
        return const {
          '/cashier',
          '/cashier/menu',
          '/order-detail',
        }.contains(path);
    }
  }
}

// ==================== PROVIDERS & MODELS ====================

// ---- PRODUCTS (REAL DATA FROM SUPABASE - TABEL menus) ----
final productsProvider = NotifierProvider<ProductsController, List<Product>>(
  ProductsController.new,
);

class ProductsController extends Notifier<List<Product>> {
  final _supabase = Supabase.instance.client;

  @override
  List<Product> build() {
    _loadProducts();
    return [];
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _supabase
          .from('menus')
          .select()
          .order('created_at', ascending: false);

      state = data.map<Product>((json) {
        return Product.fromMenuJson(json);
      }).toList();
      
      print('DEBUG: Loaded ${state.length} products from menus');
    } catch (e) {
      print('Error loading menus: $e');
    }
  }

  Future<void> add(ProductDraft draft) async {
    try {
      await _supabase.from('menus').insert({
        'name': draft.name,
        'description': '${draft.category} menu',
        'price': draft.price,
        'category': draft.category,
        'is_available': true,  // Default available pas pertama dibuat
      });

      await _loadProducts();
    } catch (e) {
      print('Error adding menu: $e');
      rethrow;
    }
  }

  Future<void> update(String id, ProductDraft draft) async {
    try {
      await _supabase.from('menus').update({
        'name': draft.name,
        'category': draft.category,
        'price': draft.price,
      }).eq('id', id);

      await _loadProducts();
    } catch (e) {
      print('Error updating menu: $e');
      rethrow;
    }
  }

  Future<void> toggleAvailability(Product product) async {
    try {
      await _supabase.from('menus').update({
        'is_available': !product.isAvailable,
      }).eq('id', product.id);

      await _loadProducts();
    } catch (e) {
      print('Error toggling availability: $e');
      // Fallback: update state lokal
      state = [
        for (final item in state)
          if (item.id == product.id)
            item.copyWith(isAvailable: !item.isAvailable)
          else
            item,
      ];
    }
  }

  Future<void> refresh() async {
    await _loadProducts();
  }
}

// ---- MENU FILTER ----
final menuFilterProvider = NotifierProvider<MenuFilterController, MenuFilter>(
  MenuFilterController.new,
);

class MenuFilterController extends Notifier<MenuFilter> {
  @override
  MenuFilter build() => const MenuFilter();

  void search(String query) {
    state = state.copyWith(query: query);
  }

  void selectCategory(String category) {
    state = state.copyWith(category: category);
  }
}

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final filter = ref.watch(menuFilterProvider);
  final query = filter.query.trim().toLowerCase();

  return products.where((product) {
    final matchesCategory =
        filter.category == MenuFilter.allCategory ||
        product.category == filter.category;
    final matchesQuery =
        query.isEmpty ||
        product.name.toLowerCase().contains(query) ||
        product.category.toLowerCase().contains(query);

    return matchesCategory && matchesQuery;
  }).toList();
});

// ---- CART ----
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

  void remove(Product product) {
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.product.id != product.id) line,
      ],
    );
  }

  void clear() {
    state = const CartState(lines: []);
  }
}

// ---- PAYMENT ----
final paymentMethodProvider =
    NotifierProvider<PaymentMethodController, PaymentMethod>(
      PaymentMethodController.new,
    );

class PaymentMethodController extends Notifier<PaymentMethod> {
  @override
  PaymentMethod build() => PaymentMethod.qris;

  void select(PaymentMethod method) {
    state = method;
  }
}

// ---- CUSTOMER INFO ----
class CustomerInfo {
  final String name;
  final String table;

  const CustomerInfo({this.name = '', this.table = ''});

  CustomerInfo copyWith({String? name, String? table}) {
    return CustomerInfo(
      name: name ?? this.name,
      table: table ?? this.table,
    );
  }
}

class CustomerInfoController extends Notifier<CustomerInfo> {
  @override
  CustomerInfo build() => const CustomerInfo();

  void update({required String name, required String table}) {
    state = CustomerInfo(name: name, table: table);
  }

  void clear() {
    state = const CustomerInfo();
  }
}

final customerInfoProvider =
    NotifierProvider<CustomerInfoController, CustomerInfo>(
      CustomerInfoController.new,
    );

// ---- CASHIER ORDERS (REAL DATA FROM SUPABASE) ----
final cashierOrdersProvider =
    NotifierProvider<CashierOrdersController, List<CashierOrder>>(
      CashierOrdersController.new,
    );

class CashierOrdersController extends Notifier<List<CashierOrder>> {
  final _supabase = Supabase.instance.client;

  @override
  List<CashierOrder> build() {
    _loadOrders();
    return [];
  }

  Future<void> _loadOrders() async {
    try {
      final ordersData = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      List<CashierOrder> orders = [];

      for (final orderJson in ordersData) {
        // Ambil items untuk setiap order
        final itemsData = await _supabase
            .from('order_items')
            .select()
            .eq('order_id', orderJson['id']);

        final items = itemsData.map<OrderItem>((item) {
          return OrderItem(
            name: item['menu_id'] ?? '',  // Nanti bisa di-join dengan menus
            quantity: item['quantity'] ?? 0,
            subtotal: item['subtotal'] ?? 0,
          );
        }).toList();

        orders.add(CashierOrder.fromOrderJson(orderJson, items));
      }

      print('DEBUG: Loaded ${orders.length} orders from database');
      state = orders;
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  CashierOrder get selectedOrder {
    if (state.isEmpty) {
      return CashierOrder.empty();
    }
    return state.first;
  }

  Future<void> markOrderReady(String orderId) async {
    try {
      await _supabase.from('orders').update({
        'order_status': 'ready',
      }).eq('id', orderId);

      await _loadOrders();
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> addOrder({
    required String customer,
    required String note,
    required CartState cart,
  }) async {
    try {
      print('=== ADDING ORDER ===');
      print('Customer: $customer');
      print('Note: $note');
      print('Total: ${cart.total}');

      // 1. Insert ke tabel orders
      final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final orderResponse = await _supabase.from('orders').insert({
        'order_number': orderNumber,
        'user_id': _supabase.auth.currentUser?.id,
        'total_amount': cart.total,
        'order_status': 'pending',
        'payment_status': 'paid',
        'payment_method': 'qris',
        'table_number': note.contains('Meja') ? note.replaceAll('Meja ', '') : null,
      }).select();

      if (orderResponse.isEmpty) {
        throw Exception('Gagal membuat order');
      }

      final orderId = orderResponse.first['id'];
      print('Order created: $orderNumber (ID: $orderId)');

      // 2. Insert ke tabel order_items
      for (final line in cart.lines) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'menu_id': line.product.id,
          'quantity': line.quantity,
          'price': line.product.price,
          'subtotal': line.subtotal,
        });
        print('Item added: ${line.product.name} x${line.quantity}');
      }

      print('=== ORDER COMPLETED ===');

      // 3. Refresh daftar order
      await _loadOrders();
    } catch (e) {
      print('Error adding order: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadOrders();
  }
}

// ==================== MODELS ====================

class MenuFilter {
  const MenuFilter({this.query = '', this.category = allCategory});

  static const allCategory = 'All';

  final String query;
  final String category;

  MenuFilter copyWith({String? query, String? category}) {
    return MenuFilter(
      query: query ?? this.query,
      category: category ?? this.category,
    );
  }
}

enum PaymentMethod { qris, cash }

enum OrderStatus { paid, preparing, ready, pickedUp }

extension PaymentMethodText on PaymentMethod {
  String get title {
    switch (this) {
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}

extension OrderStatusText on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Picked up';
    }
  }

  int get step {
    switch (this) {
      case OrderStatus.paid:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.pickedUp:
        return 3;
    }
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
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final Color color;
  final IconData icon;
  final bool isAvailable;

  Product copyWith({
    String? name,
    String? category,
    int? price,
    Color? color,
    IconData? icon,
    bool? isAvailable,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory Product.fromMenuJson(Map<String, dynamic> json) {
    final categoryIcons = {
      'Meals': Icons.rice_bowl,
      'Drinks': Icons.local_cafe,
      'Snacks': Icons.fastfood,
      'Dessert': Icons.bakery_dining,
    };

    final categoryColors = {
      'Meals': const Color(0xFFFFD7C2),
      'Drinks': const Color(0xFFD9F1E2),
      'Snacks': const Color(0xFFFFEDB5),
      'Dessert': const Color(0xFFE7D4C5),
    };

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      color: categoryColors[json['category']] ?? const Color(0xFFFFD7C2),
      icon: categoryIcons[json['category']] ?? Icons.restaurant_menu,
      isAvailable: json['is_available'] ?? true,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product.fromMenuJson(json);
  }
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.category,
    required this.price,
    required this.color,
    required this.icon,
  });

  final String name;
  final String category;
  final int price;
  final Color color;
  final IconData icon;
}

class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.subtotal,
  });

  final String name;
  final int quantity;
  final int subtotal;
}

class CashierOrder {
  const CashierOrder({
    required this.id,
    required this.customer,
    required this.status,
    required this.total,
    required this.accent,
    required this.items,
    required this.note,
    required this.orderNumber,
  });

  final String id;
  final String orderNumber;
  final String customer;
  final OrderStatus status;
  final int total;
  final Color accent;
  final List<OrderItem> items;
  final String note;

  CashierOrder copyWith({OrderStatus? status}) {
    return CashierOrder(
      id: id,
      orderNumber: orderNumber,
      customer: customer,
      status: status ?? this.status,
      total: total,
      accent: accent,
      items: items,
      note: note,
    );
  }

  factory CashierOrder.fromOrderJson(Map<String, dynamic> json, List<OrderItem> items) {
    final statusColors = {
      'pending': const Color(0xFFFFD5E5),
      'preparing': const Color(0xFFFFEDB5),
      'ready': const Color(0xFFD9F1E2),
      'completed': const Color(0xFFE7D4C5),
    };

    // Ambil customer name dari user_id (nanti bisa di-join)
    final tableNum = json['table_number'];
    final note = tableNum != null ? 'Meja $tableNum' : 'Take away';

    return CashierOrder(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      customer: 'Customer', // Nanti bisa diganti dengan join ke users
      status: _parseStatus(json['order_status']),
      total: json['total_amount'] ?? 0,
      accent: statusColors[json['order_status']] ?? const Color(0xFFFFEDB5),
      items: items,
      note: note,
    );
  }

  static CashierOrder empty() {
    return const CashierOrder(
      id: '',
      orderNumber: '',
      customer: '',
      status: OrderStatus.paid,
      total: 0,
      accent: Color(0xFFFFEDB5),
      items: [],
      note: '',
    );
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatus.paid;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.pickedUp;
      default:
        return OrderStatus.paid;
    }
  }
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

// ==================== EXTENSIONS ====================
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