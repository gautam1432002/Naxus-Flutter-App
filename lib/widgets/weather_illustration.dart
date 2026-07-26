import 'dart:math' as math;
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
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Pulsing and rotating sun
    final pulse = math.sin(time * math.pi * 4) * 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * math.pi * 2);
    canvas.drawCircle(Offset.zero, radius + pulse, paint);
    
    // Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final p1 = Offset(math.cos(angle) * (radius + 5), math.sin(angle) * (radius + 5));
      final p2 = Offset(math.cos(angle) * (radius + 15), math.sin(angle) * (radius + 15));
      canvas.drawLine(p1, p2, rayPaint);
    }
    canvas.restore();
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final floatOffset = math.sin(time * math.pi * 2) * 5;
    final cloudCenter = Offset(center.dx, center.dy + floatOffset);

    // Base cloud shapes
    final r1 = width * 0.25;
    final r2 = width * 0.35;
    final r3 = width * 0.2;
    
    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.2, cloudCenter.dy), r1, shadowPaint);
    canvas.drawCircle(cloudCenter, r2, shadowPaint);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.25, cloudCenter.dy + 10), r3, shadowPaint);

    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.2, cloudCenter.dy), r1, paint);
    canvas.drawCircle(cloudCenter, r2, paint);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.25, cloudCenter.dy + 10), r3, paint);
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      double t = (time + (i * 0.2)) % 1.0;
      double x = size.width * 0.2 + (i * size.width * 0.15);
      double y = size.height * 0.5 + (t * size.height * 0.5);
      
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 10), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      double t = (time + (i * 0.15)) % 1.0;
      double x = size.width * 0.2 + (i * size.width * 0.12) + math.sin(t * math.pi * 4) * 10;
      double y = size.height * 0.5 + (t * size.height * 0.5);
      
      canvas.drawCircle(Offset(x, y), 3, paint);
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
