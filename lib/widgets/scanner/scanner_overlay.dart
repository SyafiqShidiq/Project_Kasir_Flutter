import 'package:flutter/material.dart';

import 'scanner_corner_painter.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final scanSize =
        (screenSize.width * 0.7).clamp(220.0, 320.0);

    return IgnorePointer(
      child: Stack(
        children: [
          // Overlay seluruh layar
          CustomPaint(
            size: screenSize,
            painter: OverlayPainter(
              scanSize: scanSize,
            ),
          ),

          // Corner scanner
          Center(
            child: SizedBox(
              width: scanSize,
              height: scanSize,
              child: const CustomPaint(
                painter: ScannerCornerPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OverlayPainter extends CustomPainter {
  OverlayPainter({
    required this.scanSize,
  });

  final double scanSize;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.55);

    final background =
        Path()
          ..addRect(
            Rect.fromLTWH(
              0,
              0,
              size.width,
              size.height,
            ),
          );

    final cutoutRect = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height / 2,
      ),
      width: scanSize,
      height: scanSize,
    );

    final cutout =
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              cutoutRect,
              const Radius.circular(24),
            ),
          );

    final result = Path.combine(
      PathOperation.difference,
      background,
      cutout,
    );

    canvas.drawPath(result, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.scanSize != scanSize;
  }
}