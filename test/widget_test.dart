import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_kasir_flutter/main.dart';

void main() {
  testWidgets('menampilkan halaman menu utama', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SmartCashierApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('SmartCashier'), findsNothing);
    expect(find.text('Crispy Chicken Bowl'), findsOneWidget);
    expect(find.byType(CustomerNavigationBar), findsOneWidget);
  });

  testWidgets('menambahkan produk ke cart', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SmartCashierApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crispy Chicken Bowl'));
    await tester.pumpAndSettle();

    expect(find.text('1 items'), findsOneWidget);

    await tester.tap(find.text('Cart').last);
    await tester.pumpAndSettle();

    expect(find.text('Your order'), findsOneWidget);
    expect(find.text('Crispy Chicken Bowl'), findsAtLeastNWidgets(1));
  });
}
