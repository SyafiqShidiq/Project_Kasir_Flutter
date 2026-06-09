import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:project_kasir_flutter/main.dart';

void main() {
  testWidgets('opens SmartCashier login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCashierApp()));
    await tester.pumpAndSettle();

    expect(find.text('SmartCashier'), findsOneWidget);
    expect(find.text('Masuk sebagai kasir'), findsOneWidget);
    expect(find.text('Masuk sebagai user'), findsOneWidget);
  });

  testWidgets('adds item to cart from menu', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCashierApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk sebagai user'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crispy Chicken Bowl'));
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('1 items'), findsOneWidget);
  });

  testWidgets('customer cannot open cashier routes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCashierApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk sebagai user'));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(CustomerHomeScreen)));
    router.go('/cashier');
    await tester.pumpAndSettle();

    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.byType(CashierDashboardScreen), findsNothing);
  });

  testWidgets('cashier cannot open customer routes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCashierApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk sebagai kasir'));
    await tester.pumpAndSettle();

    final router = GoRouter.of(
      tester.element(find.byType(CashierDashboardScreen)),
    );
    router.go('/');
    await tester.pumpAndSettle();

    expect(find.byType(CashierDashboardScreen), findsOneWidget);
    expect(find.byType(CustomerHomeScreen), findsNothing);
  });
}
