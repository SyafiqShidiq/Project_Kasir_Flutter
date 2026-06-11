import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const ProviderScope(child: SmartCashierApp()));
}

enum AppRole { customer, cashier }

class AppAuthState {
  const AppAuthState({
    required this.isSignedIn,
    this.email,
    this.fullName,
    this.role,
  });

  const AppAuthState.unauthenticated()
    : isSignedIn = false,
      email = null,
      fullName = null,
      role = null;

  const AppAuthState.signedIn({required this.role, this.email, this.fullName})
    : isSignedIn = true;

  final bool isSignedIn;
  final String? email;
  final String? fullName;
  final AppRole? role;

  String get displayName => fullName?.trim().isNotEmpty == true
      ? fullName!.trim()
      : email ?? 'Pengguna';

  static AppAuthState fromSession(Session? session) {
    final user = session?.user;
    if (user == null) {
      return const AppAuthState.unauthenticated();
    }

    return AppAuthState.signedIn(
      role: _roleFromUser(user),
      email: user.email,
      fullName: _readUserName(user),
    );
  }
}

final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authProvider = NotifierProvider<AuthController, AppAuthState>(
  AuthController.new,
);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.uri.path;

      if (!authState.isSignedIn) {
        return location == '/login' || location == '/register'
            ? null
            : '/login';
      }

      final role = authState.role;
      if (role == null) {
        return '/login';
      }

      if (location == '/login' || location == '/register') {
        return role.homePath;
      }

      if (!role.canAccess(location)) {
        return role.homePath;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterUserScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
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
});

class AuthController extends Notifier<AppAuthState> {
  late final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AppAuthState build() {
    _supabase = ref.read(supabaseProvider);
    _authSubscription ??= _supabase.auth.onAuthStateChange.listen(
      (data) {
        state = AppAuthState.fromSession(data.session);
      },
      onError: (error, stackTrace) {
        debugPrint('Supabase auth stream error: $error');
      },
    );
    ref.onDispose(() => _authSubscription?.cancel());
    return AppAuthState.fromSession(_supabase.auth.currentSession);
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: await resolveAuthEmail(email),
      password: password,
    );
    state = AppAuthState.fromSession(response.session);
  }

  Future<String> registerCustomer({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final input = email.trim();
    final resolvedEmail = generateRegisterEmail(input);
    final response = await _supabase.auth.signUp(
      email: resolvedEmail,
      password: password,
      data: <String, dynamic>{
        'role': 'customer',
        'full_name': fullName.trim(),
        'alias': input,
      },
    );
    if (input.isNotEmpty) {
      await rememberAuthEmail(input, resolvedEmail);
    }
    state = AppAuthState.fromSession(response.session);
    return resolvedEmail;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AppAuthState.unauthenticated();
  }
}

AppRole _roleFromUser(User user) {
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final rawRole = metadata['role'];
  if (rawRole is String && rawRole.toLowerCase() == 'cashier') {
    return AppRole.cashier;
  }

  return AppRole.customer;
}

String? _readUserName(User user) {
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final rawName = metadata['full_name'];
  if (rawName is String && rawName.trim().isNotEmpty) {
    return rawName.trim();
  }

  final email = user.email;
  return email?.isNotEmpty == true ? email : null;
}

String normalizeEmailInput(String input) {
  final trimmed = input.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  if (trimmed.contains('@')) {
    return trimmed;
  }

  return '$trimmed@dummy.local';
}

String generateRegisterEmail(String input) {
  final trimmed = input.trim().toLowerCase();
  if (trimmed.contains('@')) {
    return trimmed;
  }

  final alias = _sanitizeEmailAlias(trimmed);
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final nonce = Random.secure().nextInt(1 << 32).toRadixString(36);
  return '$alias.$stamp$nonce@dummy.local';
}

Future<String> resolveAuthEmail(String input) async {
  final trimmed = input.trim().toLowerCase();
  if (trimmed.contains('@')) {
    return trimmed;
  }

  final rememberedEmail = await lookupRememberedAuthEmail(trimmed);
  if (rememberedEmail != null) {
    return rememberedEmail;
  }

  return '$trimmed@dummy.local';
}

String _sanitizeEmailAlias(String value) {
  final sanitized = value.replaceAll(RegExp(r'[^a-z0-9]+'), '.');
  final collapsed = sanitized.replaceAll(RegExp(r'\.+'), '.').trim();
  final trimmed = collapsed.replaceAll(RegExp(r'^\.+|\.+$'), '');
  return trimmed.isEmpty ? 'user' : trimmed;
}

String _authEmailKey(String alias) {
  return 'auth_email_${_sanitizeEmailAlias(alias)}';
}

Future<void> rememberAuthEmail(String alias, String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_authEmailKey(alias), email);
}

Future<String?> lookupRememberedAuthEmail(String alias) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_authEmailKey(alias));
}

String? validateLoginAlias(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Email atau username wajib diisi';
  }

  if (text.contains(' ')) {
    return 'Email atau username tidak boleh mengandung spasi';
  }

  if (text.endsWith('@')) {
    return 'Format email belum lengkap';
  }

  return null;
}

extension AppRoleRoutes on AppRole {
  String get homePath {
    switch (this) {
      case AppRole.customer:
        return '/';
      case AppRole.cashier:
        return '/cashier';
    }
  }

  bool canAccess(String path) {
    switch (this) {
      case AppRole.customer:
        return const {
          '/',
          '/cart',
          '/checkout',
          '/payment',
          '/tracking',
        }.contains(path);
      case AppRole.cashier:
        return const {'/cashier', '/order-detail'}.contains(path);
    }
  }
}

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

final menuFilterProvider = NotifierProvider<MenuFilterController, MenuFilter>(
  MenuFilterController.new,
);

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

final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

final paymentMethodProvider =
    NotifierProvider<PaymentMethodController, PaymentMethod>(
      PaymentMethodController.new,
    );

final cashierOrdersProvider =
    NotifierProvider<CashierOrdersController, List<CashierOrder>>(
      CashierOrdersController.new,
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

class PaymentMethodController extends Notifier<PaymentMethod> {
  @override
  PaymentMethod build() => PaymentMethod.qris;

  void select(PaymentMethod method) {
    state = method;
  }
}

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
  });

  final String id;
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login gagal: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
              'Masuk memakai akun Supabase untuk role user atau kasir.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SmartCashierTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            if (authState.isSignedIn)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: SmartCashierTheme.primary,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.verified),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Login aktif sebagai ${authState.displayName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email / username',
                        hintText: 'contoh: budi atau budi@example.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: validateLoginAlias,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password akun',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi';
                        }

                        if (value.length < 6) {
                          return 'Minimal 6 karakter';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: const Text('Masuk'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : () => context.go('/register'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Daftar user'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterUserScreen extends ConsumerStatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  ConsumerState<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends ConsumerState<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final registeredEmail = await ref
          .read(authProvider.notifier)
          .registerCustomer(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) return;

      final authState = ref.read(authProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun user berhasil dibuat. Email login: $registeredEmail',
          ),
        ),
      );
      if (!authState.isSignedIn) {
        context.go('/login');
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registrasi gagal: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar User'),
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SmartCashierLogo(size: 84),
            const SizedBox(height: 24),
            Text(
              'Buat akun user baru',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Akun yang dibuat dari sini selalu tersimpan di Supabase sebagai customer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SmartCashierTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      hintText: 'contoh: Budi Santoso',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama wajib diisi';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email / username',
                      hintText: 'contoh: budi atau budi@example.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: validateLoginAlias,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }

                      if (value.length < 6) {
                        return 'Minimal 6 karakter';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi password',
                      hintText: 'Ulangi password yang sama',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }

                      if (value != _passwordController.text) {
                        return 'Password tidak sama';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: const Text('Buat akun user'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Kembali ke login'),
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
    final products = ref.watch(filteredProductsProvider);
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
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
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
}

class CashierDashboardScreen extends ConsumerWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(cashierOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
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
              const Expanded(
                child: MetricCard(
                  label: 'Paid',
                  value: '31',
                  icon: Icons.verified_user_outlined,
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
          for (final order in orders) ...[
            OrderTile(order: order),
            const SizedBox(height: 10),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Queue refreshed')));
        },
        backgroundColor: SmartCashierTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh queue'),
      ),
      bottomNavigationBar: const CashierNavigationBar(),
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

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final selectedPayment = ref.watch(paymentMethodProvider);

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
                  selected: selectedPayment == PaymentMethod.qris,
                  onTap: () => ref
                      .read(paymentMethodProvider.notifier)
                      .select(PaymentMethod.qris),
                ),
                const Divider(height: 24),
                PaymentOption(
                  icon: Icons.payments_outlined,
                  title: 'Cash',
                  subtitle: 'Pay at cashier',
                  selected: selectedPayment == PaymentMethod.cash,
                  onTap: () => ref
                      .read(paymentMethodProvider.notifier)
                      .select(PaymentMethod.cash),
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
        label: selectedPayment == PaymentMethod.qris
            ? 'Pay now'
            : 'Place order',
        enabled: cart.itemCount > 0,
        onPressed: () {
          if (selectedPayment == PaymentMethod.qris) {
            context.go('/payment');
            return;
          }

          ref.read(cartProvider.notifier).clear();
          context.go('/tracking');
        },
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

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(cashierOrdersProvider).first;

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
        children: [
          OrderHeaderCard(order: order),
          const SizedBox(height: 12),
          OrderProgress(currentStep: order.status.step),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Pickup details',
            child: Column(
              children: [
                DetailRow(label: 'Order', value: order.id),
                const Divider(height: 24),
                const DetailRow(label: 'Counter', value: 'Pickup A'),
                const Divider(height: 24),
                DetailRow(
                  label: 'Estimated ready',
                  value: order.status == OrderStatus.ready
                      ? 'Ready now'
                      : '8 minutes',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerNavigationBar(activeIndex: 2),
    );
  }
}

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
            context.go('/');
          case 1:
            context.go('/cart');
          case 2:
            context.go('/tracking');
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
      ],
    );
  }
}

class CashierNavigationBar extends StatelessWidget {
  const CashierNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/cashier');
          case 1:
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
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
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
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
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
        ),
      ),
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
                  onPressed: () => context.go('/'),
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

class CartMenuPicker extends ConsumerWidget {
  const CartMenuPicker({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return SectionCard(
      title: title,
      child: Column(
        children: [
          for (final product in products) ...[
            SuggestedProductTile(product: product),
            if (product != products.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class SuggestedProductTile extends ConsumerWidget {
  const SuggestedProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: product.color,
        foregroundColor: SmartCashierTheme.primaryDark,
        child: Icon(product.icon),
      ),
      title: Text(product.name),
      subtitle: Text('${product.category} - ${product.price.rupiah}'),
      trailing: IconButton.filled(
        tooltip: 'Tambah ${product.name}',
        onPressed: () => ref.read(cartProvider.notifier).add(product),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
