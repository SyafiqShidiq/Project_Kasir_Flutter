import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/app_role.dart';
import 'user_home_screen.dart';
import 'cashier_home_screen.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    
    // Cek session dulu
    if (authService.currentSession == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Ambil role dari future
    final roleFuture = ref.watch(userRoleProvider);

    return roleFuture.when(
      data: (role) {
        if (role == null) {
          // Role null, redirect ke login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Tampilkan sesuai role
        switch (role) {
          case AppRole.user:
            return const UserHomeScreen();
          case AppRole.cashier:
            return const CashierHomeScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        // Error, redirect ke login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/');
          }
        });
        return const Scaffold(
          body: Center(
            child: Text('Error loading role. Redirecting...'),
          ),
        );
      },
    );
  }
}