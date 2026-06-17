import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthTestPage extends ConsumerWidget {
  const AuthTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              authService.currentSession != null
                  ? 'SUDAH LOGIN'
                  : 'BELUM LOGIN',
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await authService.logout();

                debugPrint(
                  'Session Exists: ${authService.currentSession != null}',
                );

                debugPrint(
                  'Current User: ${authService.currentUser?.email}',
                );
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}