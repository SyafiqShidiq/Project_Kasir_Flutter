import 'package:flutter/material.dart';
import '../../theme/smart_cashier_theme.dart';

class ScannerBottomPanel extends StatelessWidget {
  const ScannerBottomPanel({
    super.key,
    required this.onFlashPressed,
    required this.onSwitchCameraPressed,
  });

  final VoidCallback onFlashPressed;
  final VoidCallback onSwitchCameraPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: SmartCashierTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SmartCashierTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Arahkan kamera ke QR Merchant\nyang tersedia di meja.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SmartCashierTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'QR akan dipindai secara otomatis.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SmartCashierTheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onFlashPressed,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Flash'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onSwitchCameraPressed,
                      icon: const Icon(Icons.flip_camera_android),
                      label: const Text('Kamera'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}