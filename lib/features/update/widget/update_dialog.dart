import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showUpdateDialog({
  required BuildContext context,
  required String latestVersion,
  required String playstoreUrl,
  required bool forceUpdate,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: !forceUpdate,
    builder: (_) {
      return AlertDialog(
        title: const Text('Update Tersedia'),
        content: Text(
          'Versi terbaru ($latestVersion) telah tersedia.\n\n'
          'Silakan update aplikasi untuk mendapatkan fitur terbaru.',
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti'),
            ),
          FilledButton(
            onPressed: () async {
              final uri = Uri.parse(playstoreUrl);

              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Update'),
          ),
        ],
      );
    },
  );
}