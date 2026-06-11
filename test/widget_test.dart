import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:project_kasir_flutter/main.dart';

class FakeAuthController extends AuthController {
  @override
  AppAuthState build() => const AppAuthState.unauthenticated();

  @override
  Future<String> registerCustomer({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = AppAuthState.signedIn(
      role: AppRole.customer,
      email: email,
      fullName: fullName,
    );
    return email;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    state = AppAuthState.signedIn(
      role: email.toLowerCase().contains('cashier')
          ? AppRole.cashier
          : AppRole.customer,
      email: email,
      fullName: email.split('@').first,
    );
  }

  @override
  Future<void> signOut() async {
    state = const AppAuthState.unauthenticated();
  }
}

Widget buildTestApp() {
  return ProviderScope(
    overrides: [authProvider.overrideWith(FakeAuthController.new)],
    child: const SmartCashierApp(),
  );
}

void main() {
  testWidgets('opens SmartCashier login screen', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('SmartCashier'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar user'), findsOneWidget);
  });

  testWidgets('registers a customer account', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daftar user'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Budi User');
    await tester.enterText(find.byType(TextFormField).at(1), 'budi');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
    await tester.drag(find.byType(ListView).last, const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat akun user'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.byType(CashierDashboardScreen), findsNothing);
  });

  testWidgets('logs in customer and can add item to cart', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crispy Chicken Bowl'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('1 items'), findsOneWidget);
  });

  testWidgets('customer cannot open cashier routes', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(CustomerHomeScreen)));
    router.go('/cashier');
    await tester.pumpAndSettle();

    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.byType(CashierDashboardScreen), findsNothing);
  });

  testWidgets('logs in cashier and lands on dashboard', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'cashier');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.byType(CashierDashboardScreen), findsOneWidget);
    expect(find.byType(CustomerHomeScreen), findsNothing);
  });
}
