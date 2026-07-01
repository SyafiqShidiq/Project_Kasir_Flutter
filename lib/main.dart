import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'screens/user_home_screen.dart';
import 'screens/cashier_home_screen.dart';
import 'models/app_role.dart';
import 'services/order_service.dart';
import 'theme/smart_cashier_theme.dart';
import 'providers/order_provider.dart';
import 'models/cart_model.dart';
import 'models/menu_model.dart';
import 'models/order_model.dart' as order_model;
import '../screens/register_screen.dart';
import 'providers/menu_filter_provider.dart';
import 'providers/payment_provider.dart';

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

// ==================== PROVIDERS & MODELS ====================

// ---- CART ----

// ---- PAYMENT ----

// ---- CUSTOMER INFO ----


// ---- CASHIER ORDERS (REAL DATA FROM SUPABASE) ----
final cashierOrdersProvider =
    NotifierProvider<CashierOrdersController, List<order_model.CashierOrder>>(
      CashierOrdersController.new,
    );

class CashierOrdersController extends Notifier<List<order_model.CashierOrder>> {
  final _supabase = Supabase.instance.client;
  late final OrderService _service;

  @override
  List<order_model.CashierOrder> build() {
    _service = ref.read(orderServiceProvider);
    _loadOrders();
    return [];
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _service.getOrders();

      print('DEBUG: Loaded ${orders.length} orders from database');

      state = orders;
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  order_model.CashierOrder get selectedOrder {
    if (state.isEmpty) {
      return order_model.CashierOrder.empty();
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