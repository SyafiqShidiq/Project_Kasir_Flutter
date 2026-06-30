import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'screens/user_home_screen.dart';
import 'screens/cashier_home_screen.dart';
import 'screens/report_screen.dart';
import 'models/app_role.dart';
import 'models/order_model.dart';
import 'models/cart_model.dart';
import 'models/menu_model.dart';
import '../screens/register_screen.dart';
import 'providers/menu_filter_provider.dart';

import 'models/product_draft.dart';

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

            GoRoute(
        path: '/report',
        builder: (context, state) => const ReportScreen(),
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

// ---- CART ----
final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState(lines: []);

  void add(MenuModel product) {
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

  void decrease(MenuModel product) {
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

  void remove(MenuModel product) {
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
            quantity: (item['quantity'] as num?)?.toInt() ?? 0,
            subtotal: (item['subtotal'] as num?)?.toInt() ?? 0,
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
        'table_number': note.contains('Meja') ? int.tryParse(note.replaceAll('Meja ', '')) ?? 0 : 0,
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
      total: (json['total_amount'] as num?)?.toInt() ?? 0,
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

class LegacyCartState {
  const LegacyCartState({required this.lines});

  final List<CartLine> lines;
  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);
  int get subtotal => lines.fold(0, (total, line) => total + line.subtotal);
  int get tax => (subtotal * 0.1).round();
  int get service => itemCount == 0 ? 0 : 4000;
  int get total => subtotal + tax + service;

  LegacyCartState copyWith({List<CartLine>? lines}) {
    return LegacyCartState(lines: lines ?? this.lines);
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