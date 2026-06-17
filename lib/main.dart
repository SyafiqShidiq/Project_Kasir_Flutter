import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'screens/user_home_screen.dart';
import 'screens/cashier_home_screen.dart';
import 'models/app_role.dart';

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

// ---- PRODUCTS ----
final productsProvider = NotifierProvider<ProductsController, List<Product>>(
  ProductsController.new,
);

class ProductsController extends Notifier<List<Product>> {
  @override
  List<Product> build() => const [
    Product(
      id: 'p1',
      name: 'Crispy Chicken Bowl',
      category: 'Meals',
      price: 28000,
      stock: 24,
      color: Color(0xFFFFD7C2),
      icon: Icons.rice_bowl,
    ),
    Product(
      id: 'p2',
      name: 'Beef Teriyaki',
      category: 'Meals',
      price: 36000,
      stock: 18,
      color: Color(0xFFDDE8D4),
      icon: Icons.lunch_dining,
    ),
    Product(
      id: 'p3',
      name: 'Iced Matcha Latte',
      category: 'Drinks',
      price: 22000,
      stock: 32,
      color: Color(0xFFD9F1E2),
      icon: Icons.local_cafe,
    ),
    Product(
      id: 'p4',
      name: 'Berry Soda',
      category: 'Drinks',
      price: 18000,
      stock: 27,
      color: Color(0xFFFFD5E5),
      icon: Icons.local_drink,
    ),
    Product(
      id: 'p5',
      name: 'French Fries',
      category: 'Snacks',
      price: 17000,
      stock: 8,
      color: Color(0xFFFFEDB5),
      icon: Icons.fastfood,
    ),
    Product(
      id: 'p6',
      name: 'Chocolate Waffle',
      category: 'Dessert',
      price: 25000,
      stock: 0,
      isAvailable: false,
      color: Color(0xFFE7D4C5),
      icon: Icons.bakery_dining,
    ),
  ];

  void add(ProductDraft draft) {
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    state = [
      Product(
        id: id,
        name: draft.name,
        category: draft.category,
        price: draft.price,
        stock: draft.stock,
        color: draft.color,
        icon: draft.icon,
        isAvailable: draft.stock > 0,
      ),
      ...state,
    ];
  }

  void update(String id, ProductDraft draft) {
    state = [
      for (final product in state)
        if (product.id == id)
          product.copyWith(
            name: draft.name,
            category: draft.category,
            price: draft.price,
            stock: draft.stock,
            color: draft.color,
            icon: draft.icon,
            isAvailable: draft.stock > 0,
          )
        else
          product,
    ];
  }

  void toggleAvailability(Product product) {
    state = [
      for (final item in state)
        if (item.id == product.id)
          item.copyWith(isAvailable: !item.isAvailable)
        else
          item,
    ];
  }

  void adjustStock(Product product, int delta) {
    state = [
      for (final item in state)
        if (item.id == product.id)
          item.copyWith(
            stock: (item.stock + delta).clamp(0, 999),
            isAvailable: item.stock + delta > 0,
          )
        else
          item,
    ];
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

// ---- CASHIER ORDERS ----
final cashierOrdersProvider =
    NotifierProvider<CashierOrdersController, List<CashierOrder>>(
      CashierOrdersController.new,
    );

class CashierOrdersController extends Notifier<List<CashierOrder>> {
  @override
  List<CashierOrder> build() => const [
    CashierOrder(
      id: '#402',
      customer: 'Dina',
      status: OrderStatus.preparing,
      total: 86000,
      accent: Color(0xFFFFEDB5),
      items: [
        OrderItem(name: 'Crispy Chicken Bowl', quantity: 2, subtotal: 56000),
        OrderItem(name: 'Iced Matcha Latte', quantity: 1, subtotal: 22000),
      ],
      note: 'No onion. Extra sauce on the side.',
    ),
    CashierOrder(
      id: '#403',
      customer: 'Rafi',
      status: OrderStatus.ready,
      total: 54000,
      accent: Color(0xFFD9F1E2),
      items: [
        OrderItem(name: 'Beef Teriyaki', quantity: 1, subtotal: 36000),
        OrderItem(name: 'Berry Soda', quantity: 1, subtotal: 18000),
      ],
      note: 'Take away.',
    ),
    CashierOrder(
      id: '#404',
      customer: 'Maya',
      status: OrderStatus.paid,
      total: 118000,
      accent: Color(0xFFFFD5E5),
      items: [
        OrderItem(name: 'Chocolate Waffle', quantity: 2, subtotal: 50000),
        OrderItem(name: 'French Fries', quantity: 4, subtotal: 68000),
      ],
      note: 'Serve drinks later.',
    ),
  ];

  CashierOrder get selectedOrder => state.first;

  void markSelectedReady() {
    final order = selectedOrder;
    state = [
      for (final item in state)
        if (item.id == order.id)
          item.copyWith(status: OrderStatus.ready)
        else
          item,
    ];
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
    required this.stock,
    required this.color,
    required this.icon,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final int stock;
  final Color color;
  final IconData icon;
  final bool isAvailable;

  bool get isLowStock => stock > 0 && stock <= 10;

  Product copyWith({
    String? name,
    String? category,
    int? price,
    int? stock,
    Color? color,
    IconData? icon,
    bool? isAvailable,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.color,
    required this.icon,
  });

  final String name;
  final String category;
  final int price;
  final int stock;
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
  });

  final String id;
  final String customer;
  final OrderStatus status;
  final int total;
  final Color accent;
  final List<OrderItem> items;
  final String note;

  CashierOrder copyWith({OrderStatus? status}) {
    return CashierOrder(
      id: id,
      customer: customer,
      status: status ?? this.status,
      total: total,
      accent: accent,
      items: items,
      note: note,
    );
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