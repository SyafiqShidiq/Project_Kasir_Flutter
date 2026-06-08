import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_kasir_flutter/main.dart';

void main() {
  testWidgets('opens SmartCashier login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCashierApp()));
    await tester.pumpAndSettle();

    expect(find.text('SmartCashier'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('adds item to cart from menu', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCashierApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open customer menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crispy Chicken Bowl'));
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('1 items'), findsOneWidget);
  });
}
