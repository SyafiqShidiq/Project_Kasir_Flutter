import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_gate.dart';
import '../screens/user_home_screen.dart';
import '../screens/cashier_home_screen.dart';
import '../screens/register_screen.dart';
import '../screens/report_screen.dart';
import '../screens/merchant_qr_screen.dart';
import '../screens/qr_scanner_screen.dart';

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
        path: '/order-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/merchant-qr',
        builder: (context, state) =>
            const MerchantQrScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) =>
            const QrScannerScreen(),
      ),
    ],
  );
});