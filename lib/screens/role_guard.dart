import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_role.dart';
import '../providers/auth_provider.dart';

import 'user_home_screen.dart';
import 'cashier_home_screen.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return FutureBuilder<AppRole?>(
      future: authService.getRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                snapshot.error.toString(),
              ),
            ),
          );
        }

        final role = snapshot.data;

        if (role == AppRole.cashier) {
          return const CashierHomeScreen();
        }

        return const UserHomeScreen();
      },
    );
  }
}