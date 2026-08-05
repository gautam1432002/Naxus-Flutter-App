import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class StaticDiscoverCloud extends StatelessWidget {
  const StaticDiscoverCloud({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(250, 250),
      painter: _StaticDiscoverCloudPainter(),
    );
  }
}

class _StaticDiscoverCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw Sun
    final sunCenter = Offset(center.dx + 40, center.dy - 30);
    final sunRadius = size.width * 0.22;

    // Sun Glow
    final sunGlow = Paint()
      ..shader = ui.Gradient.radial(sunCenter, sunRadius * 2, [
        const Color(0xFFFDE047).withValues(alpha: 0.5),
        const Color(0xFFFDE047).withValues(alpha: 0.0),
      ])
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(sunCenter, sunRadius * 1.5, sunGlow);

    // Sun Body
    final sunPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(sunCenter.dx, sunCenter.dy - sunRadius),
        Offset(sunCenter.dx, sunCenter.dy + sunRadius),
        [const Color(0xFFFEF08A), const Color(0xFFF59E0B)],
      );
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    // Draw Main Cloud
    final cloudWidth = size.width * 0.75;
    final cloudCenter = Offset(center.dx - 10, center.dy + 20);

    final dropShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    final cloudPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cloudCenter.dx, cloudCenter.dy - cloudWidth * 0.4),
        Offset(cloudCenter.dx, cloudCenter.dy + cloudWidth * 0.2),
        [Colors.white, const Color(0xFFE2E8F0)],
      );

    final highlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cloudCenter.dx, cloudCenter.dy - cloudWidth * 0.5),
        Offset(cloudCenter.dx, cloudCenter.dy),
        [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.0)],
      );

    final r1 = cloudWidth * 0.28;
    final r2 = cloudWidth * 0.4;
    final r3 = cloudWidth * 0.25;

    // Cloud Drop Shadow
    canvas.drawCircle(Offset(cloudCenter.dx - cloudWidth * 0.25, cloudCenter.dy + 5), r1, dropShadow);
    canvas.drawCircle(cloudCenter, r2, dropShadow);
    canvas.drawCircle(Offset(cloudCenter.dx + cloudWidth * 0.3, cloudCenter.dy + 15), r3, dropShadow);

    // Cloud Base
    canvas.drawCircle(Offset(cloudCenter.dx - cloudWidth * 0.25, cloudCenter.dy + 5), r1, cloudPaint);
    canvas.drawCircle(cloudCenter, r2, cloudPaint);
    canvas.drawCircle(Offset(cloudCenter.dx + cloudWidth * 0.3, cloudCenter.dy + 15), r3, cloudPaint);

    // Cloud Highlights
    canvas.drawCircle(Offset(cloudCenter.dx - cloudWidth * 0.25, cloudCenter.dy + 5), r1, highlightPaint);
    canvas.drawCircle(cloudCenter, r2, highlightPaint);
    canvas.drawCircle(Offset(cloudCenter.dx + cloudWidth * 0.3, cloudCenter.dy + 15), r3, highlightPaint);
    
    // Draw Secondary Front Cloud (smaller, slightly offset)
    final frontCloudCenter = Offset(center.dx + 30, center.dy + 50);
    final frontCloudWidth = size.width * 0.45;

    final frontDropShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final frontCloudPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(frontCloudCenter.dx, frontCloudCenter.dy - frontCloudWidth * 0.4),
        Offset(frontCloudCenter.dx, frontCloudCenter.dy + frontCloudWidth * 0.2),
        [Colors.white, const Color(0xFFF8FAFC)],
      );

    final fr1 = frontCloudWidth * 0.28;
    final fr2 = frontCloudWidth * 0.4;
    final fr3 = frontCloudWidth * 0.22;

    canvas.drawCircle(Offset(frontCloudCenter.dx - frontCloudWidth * 0.25, frontCloudCenter.dy + 5), fr1, frontDropShadow);
    canvas.drawCircle(frontCloudCenter, fr2, frontDropShadow);
    canvas.drawCircle(Offset(frontCloudCenter.dx + frontCloudWidth * 0.3, frontCloudCenter.dy + 15), fr3, frontDropShadow);

    canvas.drawCircle(Offset(frontCloudCenter.dx - frontCloudWidth * 0.25, frontCloudCenter.dy + 5), fr1, frontCloudPaint);
    canvas.drawCircle(frontCloudCenter, fr2, frontCloudPaint);
    canvas.drawCircle(Offset(frontCloudCenter.dx + frontCloudWidth * 0.3, frontCloudCenter.dy + 15), fr3, frontCloudPaint);
  }

  @override
  bool shouldRepaint(covariant _StaticDiscoverCloudPainter oldDelegate) => false;
}
