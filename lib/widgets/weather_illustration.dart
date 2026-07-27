import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WeatherIllustration extends StatefulWidget {
  final String conditionLabel;
  final bool isDay;
  
  const WeatherIllustration({
    super.key,
    required this.conditionLabel,
    this.isDay = true,
  });

  @override
  State<WeatherIllustration> createState() => _WeatherIllustrationState();
}

class _WeatherIllustrationState extends State<WeatherIllustration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(120, 120),
          painter: _WeatherPainter(
            condition: widget.conditionLabel.toLowerCase(),
            isDay: widget.isDay,
            time: _controller.value,
          ),
        );
      },
    );
  }
}

class _WeatherPainter extends CustomPainter {
  final String condition;
  final bool isDay;
  final double time;

  _WeatherPainter({required this.condition, required this.isDay, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    if (condition.contains('clear') || condition.contains('sun')) {
      _drawSun(canvas, center, size.width * 0.35);
    } else if (condition.contains('cloud')) {
      if (condition.contains('partly')) {
        _drawSun(canvas, Offset(center.dx + 20, center.dy - 20), size.width * 0.25);
      }
      _drawCloud(canvas, center, size.width * 0.8, const Color(0xFFF8FAFC));
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      _drawCloud(canvas, Offset(center.dx, center.dy - 10), size.width * 0.7, const Color(0xFFCBD5E1));
      _drawRain(canvas, size);
      if (condition.contains('thunder') || condition.contains('storm')) {
        _drawLightning(canvas, size);
      }
    } else if (condition.contains('snow')) {
      _drawCloud(canvas, Offset(center.dx, center.dy - 10), size.width * 0.7, const Color(0xFFE2E8F0));
      _drawSnow(canvas, size);
    } else {
      _drawSun(canvas, center, size.width * 0.35);
    }
  }

  void _drawSun(Canvas canvas, Offset center, double radius) {
    // Outer glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(center, radius * 2, [
        const Color(0xFFFDE047).withValues(alpha: 0.5),
        const Color(0xFFFDE047).withValues(alpha: 0.0),
      ])
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Inner sun body (Gradient)
    final sunPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius),
        [
          const Color(0xFFFEF08A),
          const Color(0xFFF59E0B),
        ],
      );

    // Inner shadow effect
    final shadowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
        radius,
        [
          Colors.white.withValues(alpha: 0.8),
          Colors.transparent,
        ],
      )
      ..blendMode = BlendMode.overlay;

    final pulse = math.sin(time * math.pi * 4) * 1.5;
    final r = radius + pulse;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * math.pi * 2);

    canvas.drawCircle(Offset.zero, r, sunPaint);
    canvas.drawCircle(Offset.zero, r, shadowPaint);
    
    // Sun rays
    final rayPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, r + 20),
        [
          const Color(0xFFFDE047).withValues(alpha: 0.8),
          const Color(0xFFF59E0B).withValues(alpha: 0.0),
        ],
      )
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      canvas.save();
      canvas.rotate(angle);
      canvas.drawLine(Offset(0, r + 8), Offset(0, r + 22), rayPaint);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Color baseColor) {
    // We use a dark base shadow
    final dropShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
    // Cloud body gradient
    final cloudPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - width * 0.4),
        Offset(center.dx, center.dy + width * 0.2),
        [
          Colors.white,
          baseColor,
        ],
      );

    // Subtle top highlight for 3D rim lighting
    final highlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - width * 0.5),
        Offset(center.dx, center.dy),
        [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.0),
        ],
      );

    final floatOffset = math.sin(time * math.pi * 2) * 6;
    final cloudCenter = Offset(center.dx, center.dy + floatOffset);

    // Base cloud shapes
    final r1 = width * 0.28;
    final r2 = width * 0.4;
    final r3 = width * 0.22;
    
    // Draw Drop Shadows
    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.25, cloudCenter.dy + 5), r1, dropShadow);
    canvas.drawCircle(cloudCenter, r2, dropShadow);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.3, cloudCenter.dy + 15), r3, dropShadow);

    // Draw Main Body
    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.25, cloudCenter.dy + 5), r1, cloudPaint);
    canvas.drawCircle(cloudCenter, r2, cloudPaint);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.3, cloudCenter.dy + 15), r3, cloudPaint);

    // Draw Highlights
    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.25, cloudCenter.dy + 5), r1, highlightPaint);
    canvas.drawCircle(cloudCenter, r2, highlightPaint);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.3, cloudCenter.dy + 15), r3, highlightPaint);
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(0, 20),
        [
          const Color(0xFF93C5FD).withValues(alpha: 0.9),
          const Color(0xFF3B82F6).withValues(alpha: 0.2),
        ],
      )
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      double t = (time + (i * 0.2)) % 1.0;
      double x = size.width * 0.3 + (i * size.width * 0.15);
      double y = size.height * 0.5 + (t * size.height * 0.6);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(0.2); // slight angle
      canvas.drawLine(const Offset(0, 0), const Offset(0, 15), paint);
      canvas.restore();
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < 6; i++) {
      double t = (time + (i * 0.15)) % 1.0;
      double x = size.width * 0.25 + (i * size.width * 0.15) + math.sin(t * math.pi * 4) * 8;
      double y = size.height * 0.5 + (t * size.height * 0.5);
      
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    final flash = math.sin(time * math.pi * 20);
    if (flash > 0.8) {
      final paint = Paint()
        ..color = const Color(0xFFFEF08A).withValues(alpha: 0.9)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final path = Path()
        ..moveTo(size.width * 0.5, size.height * 0.5)
        ..lineTo(size.width * 0.45, size.height * 0.7)
        ..lineTo(size.width * 0.55, size.height * 0.7)
        ..lineTo(size.width * 0.4, size.height * 0.9);
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) => true;
}
