import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:project_kasir_flutter/screens/user_home_screen.dart';
import 'package:project_kasir_flutter/screens/cashier_home_screen.dart';

void main() {
  // Test 1: UserHomeScreen langsung (paling simpel)
  testWidgets('UserHomeScreen - menampilkan menu utama', (tester) async {
    final router = GoRouter(
      initialLocation: '/user-home',
      routes: [
        GoRoute(
          path: '/user-home',
          builder: (context, state) => const UserHomeScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ponytail: specify AppBar descendant to avoid ambiguity with NavigationBar label
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Menu')), findsOneWidget);
    expect(find.text('Crispy Chicken Bowl'), findsOneWidget);
    expect(find.byType(CustomerNavigationBar), findsOneWidget);
  });

  // Test 2: Tambah produk ke cart
  testWidgets('UserHomeScreen - menambahkan produk ke cart', (tester) async {
    final router = GoRouter(
      initialLocation: '/user-home',
      routes: [
        GoRoute(
          path: '/user-home',
          builder: (context, state) => const UserHomeScreen(),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap produk pertama
    await tester.tap(find.text('Crispy Chicken Bowl').first);
    await tester.pumpAndSettle();

    // Cek badge di appbar
    expect(find.text('1 items'), findsOneWidget);

    // ponytail: tap cart icon in AppBar specifically
    await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.shopping_cart_outlined)));
    await tester.pumpAndSettle();

    // Verifikasi di halaman cart
    expect(find.text('Your order'), findsOneWidget);
    expect(find.text('Crispy Chicken Bowl'), findsAtLeastNWidgets(1));
  });

  // Test 3: Cashier Menu Screen
  testWidgets('CashierMenuScreen - tambah menu baru', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CashierMenuScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi halaman
    expect(find.text('Kelola Menu'), findsOneWidget);
    expect(find.byType(CashierMenuScreen), findsOneWidget);

    // ponytail: tap FloatingActionButton specifically instead of ambiguous Icons.add
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Isi form
    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeast(3));
    
    await tester.enterText(textFields.at(0), 'Nasi Goreng Spesial');
    await tester.enterText(textFields.at(1), '30000');
    await tester.enterText(textFields.at(2), '15');
    await tester.pumpAndSettle();

    // Simpan menu
    await tester.tap(find.text('Simpan menu'));
    await tester.pumpAndSettle();

    // Verifikasi menu berhasil ditambahkan
    expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
  });

  // Test 4: Cashier Home Screen
  testWidgets('CashierHomeScreen - menampilkan dashboard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CashierHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ponytail: specify AppBar descendant to avoid ambiguity with NavigationBar label
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')), findsOneWidget);
    expect(find.byType(CashierNavigationBar), findsOneWidget);
  });

  // Test 5: Cart Screen
  testWidgets('CartScreen - menampilkan keranjang kosong', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CartScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Cart is empty'), findsOneWidget);
  });

  // Test 6: Checkout Screen
  testWidgets('CheckoutScreen - menampilkan halaman checkout', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
  });

  // Test 7: Navigation Bar Customer
  testWidgets('CustomerNavigationBar - navigasi antar tab', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Body')),
            bottomNavigationBar: CustomerNavigationBar(activeIndex: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cek semua tab ada
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Track'), findsNothing);
  });

  // Test 8: Navigation Bar Cashier
  testWidgets('CashierNavigationBar - navigasi antar tab', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Body')),
            bottomNavigationBar: CashierNavigationBar(activeIndex: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cek semua tab ada
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });
}