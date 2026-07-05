import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';

Future<void> showMaintenanceDialog({
  required BuildContext context,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          icon: Icon(
            Icons.construction,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text(
            'Sedang Maintenance',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Aplikasi sedang menjalani proses maintenance.\n\n'
            'Silakan coba kembali beberapa saat lagi.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                FlutterExitApp.exitApp();
              },
              child: const Text('Keluar'),
            ),
          ],
        ),
      );
    },
  );
}