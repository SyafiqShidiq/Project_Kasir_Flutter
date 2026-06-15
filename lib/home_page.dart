import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class AuthTestPage extends ConsumerWidget {
  const AuthTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test'),
      ),
      body: Center(
        child: authState.when(
          data: (authState) {
            return Text(
              'Event: ${authState.event}',
              style: const TextStyle(fontSize: 20),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text(
            'Error: $error',
          ),
        ),
      ),
    );
  }
}