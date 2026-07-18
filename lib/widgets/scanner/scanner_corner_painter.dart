import 'package:flutter/material.dart';
import '../../theme/smart_cashier_theme.dart';

class ScannerCornerPainter extends CustomPainter {
  const ScannerCornerPainter({
    this.color = SmartCashierTheme.primary,
    this.strokeWidth = 4,
    this.cornerLength = 20,
    this.radius = 24,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();

    // ===== Kiri Atas =====
    path.moveTo(radius + cornerLength, 0);
    path.lineTo(radius, 0);
    path.arcToPoint(
      Offset(0, radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(0, radius + cornerLength);

    // ===== Kanan Atas =====
    path.moveTo(size.width - radius - cornerLength, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width, radius + cornerLength);

    // ===== Kanan Bawah =====
    path.moveTo(size.width, size.height - radius - cornerLength);
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width - radius - cornerLength, size.height);

    // ===== Kiri Bawah =====
    path.moveTo(radius + cornerLength, size.height);
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(0, size.height - radius - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScannerCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.radius != radius;
  }
}