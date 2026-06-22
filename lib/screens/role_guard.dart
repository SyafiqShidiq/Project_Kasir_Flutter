import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/app_role.dart';
import 'user_home_screen.dart';
import 'cashier_home_screen.dart';

class RoleGuard extends ConsumerStatefulWidget {
  const RoleGuard({super.key});

  @override
  ConsumerState<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends ConsumerState<RoleGuard> {
  AppRole? _role;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    try {
      final authService = ref.read(authServiceProvider);
      final role = await authService.getRole();
      
      print('=== ROLE DEBUG ===');
      print('Role from getRole(): $role');
      print('==================');
      
      if (mounted) {
        setState(() {
          _role = role;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching role: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check session
    final authService = ref.read(authServiceProvider);
    if (authService.currentSession == null) {
      // No session, back to login
      Future.microtask(() {
        if (context.mounted) context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Loading state
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Gagal memuat role: $_error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _fetchRole,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // No role found
    if (_role == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 48),
              const SizedBox(height: 16),
              const Text('Role tidak ditemukan'),
              const SizedBox(height: 8),
              const Text('Pastikan akun Anda terdaftar dengan role yang sesuai'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  authService.logout();
                  context.go('/');
                },
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Redirect based on role
    switch (_role!) {
      case AppRole.user:
        return const UserHomeScreen();
      case AppRole.cashier:
        return const CashierHomeScreen();
    }
  }
}