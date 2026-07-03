import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';

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

// ==================== THEME ====================

// ==================== ROUTER ====================

// ==================== AUTH CONTROLLER ====================

// ==================== PROVIDERS & MODELS ====================

// ---- CART ----

// ---- PAYMENT ----

// ---- CUSTOMER INFO ----

// ---- CASHIER ORDERS (REAL DATA FROM SUPABASE) ----

// ==================== MODELS ====================

// ==================== EXTENSIONS ====================