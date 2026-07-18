import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_parser_service.dart';
import '../widgets/scanner/scanner_bottom_panel.dart';
import '../widgets/scanner/scanner_top_bar.dart';
import '../widgets/scanner/scanner_overlay.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) async {
              if (_isScanning) return;

              _isScanning = true;

              final barcode = capture.barcodes.first;
              final qrValue = barcode.rawValue;

              if (qrValue == null) {
                _isScanning = false;
                return;
              }

              final parser = const QrParserService();
              final payload = parser.parse(qrValue);

              if (payload == null) {
                _isScanning = false;

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR tidak dikenali.'),
                  ),
                );

                return;
              }

              await _scannerController.stop();

              if (!mounted) return;

              Navigator.pop(context, payload);
            },
          ),

          const ScannerOverlay(),

          ScannerTopBar(
            onBack: () => Navigator.pop(context),
          ),

          ScannerBottomPanel(
            onFlashPressed: () {
              _scannerController.toggleTorch();
            },
            onSwitchCameraPressed: () {
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
    );
  }
}