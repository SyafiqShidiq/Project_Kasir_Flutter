import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
            onDetect: (capture) {
              // nanti kita isi
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