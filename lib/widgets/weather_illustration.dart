import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WeatherIllustration extends StatefulWidget {
  final String conditionLabel;
  final bool isDay;
  final bool animate;
  
  const WeatherIllustration({
    super.key,
    required this.conditionLabel,
    this.isDay = true,
    this.animate = true,
  });

  @override
  State<WeatherIllustration> createState() => _WeatherIllustrationState();
}

class _WeatherIllustrationState extends State<WeatherIllustration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WeatherIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
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
    
    bool hasCloud = condition.contains('cloud') || condition.contains('overcast') || condition.contains('fog') || condition.contains('rain') || condition.contains('drizzle') || condition.contains('thunder') || condition.contains('storm') || condition.contains('snow');
    bool hasRain = condition.contains('rain') || condition.contains('drizzle') || condition.contains('storm') || condition.contains('shower');
    bool hasThunder = condition.contains('thunder') || condition.contains('storm');
    bool hasSnow = condition.contains('snow');
    bool partlyCloudy = condition.contains('partly') || condition.contains('mostly clear') || condition.contains('fog');
    bool isClear = condition.contains('clear') || condition.contains('sun') || (!hasCloud);

    // Draw Celestial Body (Sun or Moon)
    if (isClear || partlyCloudy) {
       Offset celestialCenter = partlyCloudy ? Offset(center.dx + 20, center.dy - 20) : center;
       double radius = partlyCloudy ? size.width * 0.25 : size.width * 0.35;
       if (isDay) {
         _drawSun(canvas, celestialCenter, radius);
       } else {
         _drawMoon(canvas, celestialCenter, radius);
       }
    }

    // Draw Cloud
    if (hasCloud) {
       Color cloudColor = hasSnow ? const Color(0xFFE2E8F0) : (hasRain || hasThunder ? const Color(0xFF94A3B8) : const Color(0xFFF8FAFC));
       Offset cloudCenter = partlyCloudy ? center : Offset(center.dx, center.dy - 10);
       double cloudWidth = partlyCloudy ? size.width * 0.8 : size.width * 0.7;
       _drawCloud(canvas, cloudCenter, cloudWidth, cloudColor);
    }

    // Draw Precipitation
    if (hasRain) {
       _drawRealisticRain(canvas, size);
    } else if (hasSnow) {
       _drawSnow(canvas, size);
    }

    if (hasThunder) {
       _drawRealisticLightning(canvas, size);
    }
  }

  void _drawSun(Canvas canvas, Offset center, double radius) {
    // Outer glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(center, radius * 2.5, [
        const Color(0xFFFDE047).withValues(alpha: 0.6),
        const Color(0xFFFDE047).withValues(alpha: 0.0),
      ])
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
    canvas.drawCircle(center, radius * 1.8, glowPaint);

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

    // Sun rays (corona) pulsing and rotating
    final pulse = math.sin(time * math.pi * 4) * 0.1;
    final r = radius * (1.0 + pulse);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * math.pi * 2);

    canvas.drawCircle(Offset.zero, r, sunPaint);
    
    // Draw realistic tapering rays
    final rayPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, r * 1.8),
        [
          const Color(0xFFFDE047).withValues(alpha: 0.9),
          const Color(0xFFF59E0B).withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6);
      canvas.save();
      canvas.rotate(angle);
      // Tapering polygon for ray
      final path = Path()
        ..moveTo(-radius * 0.15, radius * 1.1)
        ..lineTo(radius * 0.15, radius * 1.1)
        ..lineTo(0, radius * 1.8)
        ..close();
      canvas.drawPath(path, rayPaint);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawMoon(Canvas canvas, Offset center, double radius) {
    // Moon glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(center, radius * 2.0, [
        const Color(0xFF93C5FD).withValues(alpha: 0.5),
        const Color(0xFF93C5FD).withValues(alpha: 0.0),
      ])
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Moon body
    final moonPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - radius, center.dy - radius),
        Offset(center.dx + radius, center.dy + radius),
        [
          const Color(0xFFF8FAFC), // Light grey/white
          const Color(0xFF94A3B8), // Darker grey
        ],
      );
      
    canvas.drawCircle(center, radius, moonPaint);

    // Craters
    final craterPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
      
    final craters = [
      {'x': -0.3, 'y': -0.4, 'r': 0.25},
      {'x': 0.4, 'y': -0.2, 'r': 0.15},
      {'x': -0.1, 'y': 0.5, 'r': 0.3},
      {'x': 0.5, 'y': 0.4, 'r': 0.2},
    ];
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Subtle rotation over time
    canvas.rotate(time * math.pi * 0.2);
    
    for (var c in craters) {
      canvas.drawCircle(Offset(c['x']! * radius, c['y']! * radius), c['r']! * radius, craterPaint);
    }
    canvas.restore();
  }

  void _drawCloud(Canvas canvas, Offset center, double width, Color baseColor) {
    final dropShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
    final cloudPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - width * 0.4),
        Offset(center.dx, center.dy + width * 0.2),
        [Colors.white, baseColor],
      );

    final highlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - width * 0.5),
        Offset(center.dx, center.dy),
        [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.0)],
      );

    final floatOffset = math.sin(time * math.pi * 2) * 6;
    final cloudCenter = Offset(center.dx, center.dy + floatOffset);

    final r1 = width * 0.28;
    final r2 = width * 0.4;
    final r3 = width * 0.22;
    
    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.25, cloudCenter.dy + 5), r1, dropShadow);
    canvas.drawCircle(cloudCenter, r2, dropShadow);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.3, cloudCenter.dy + 15), r3, dropShadow);

    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.25, cloudCenter.dy + 5), r1, cloudPaint);
    canvas.drawCircle(cloudCenter, r2, cloudPaint);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.3, cloudCenter.dy + 15), r3, cloudPaint);

    canvas.drawCircle(Offset(cloudCenter.dx - width * 0.25, cloudCenter.dy + 5), r1, highlightPaint);
    canvas.drawCircle(cloudCenter, r2, highlightPaint);
    canvas.drawCircle(Offset(cloudCenter.dx + width * 0.3, cloudCenter.dy + 15), r3, highlightPaint);
  }

  void _drawRealisticRain(Canvas canvas, Size size) {
    // Generate realistic droplets falling at different speeds and phases
    for (int i = 0; i < 15; i++) {
      // Offset time to create distinct falling phases
      double phase = (time * (1.5 + (i % 3) * 0.5) + (i * 0.13)) % 1.0; 
      double x = size.width * 0.2 + (i * size.width * 0.05);
      // Fall from middle of cloud to bottom
      double startY = size.height * 0.45;
      double y = startY + (phase * size.height * 0.6);
      
      // Calculate opacity based on position (fade in at top, fade out at bottom)
      double opacity = 1.0;
      if (phase < 0.2) opacity = phase / 0.2;
      if (phase > 0.8) opacity = (1.0 - phase) / 0.2;
      
      final dropPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(0, 12),
          [
            const Color(0xFF60A5FA).withValues(alpha: 0.1 * opacity), // Tail (transparent)
            const Color(0xFF2563EB).withValues(alpha: 0.9 * opacity), // Head (dense water)
          ],
        )
        ..style = PaintingStyle.fill;
        
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(0.15); // Slight wind angle
      
      // Draw a teardrop shape
      final path = Path()
        ..moveTo(0, 0) // Tail top
        ..quadraticBezierTo(2, 10, 0, 12) // Right curve down to rounded head
        ..quadraticBezierTo(-2, 10, 0, 0) // Left curve back up
        ..close();
        
      canvas.drawPath(path, dropPaint);
      canvas.restore();
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (int i = 0; i < 12; i++) {
      double t = (time * (0.5 + (i%2)*0.3) + (i * 0.15)) % 1.0;
      double x = size.width * 0.2 + (i * size.width * 0.06) + math.sin(t * math.pi * 4 + i) * 10;
      double y = size.height * 0.4 + (t * size.height * 0.6);
      
      double radius = 2.0 + (i % 3);
      double opacity = 1.0;
      if (t < 0.2) opacity = t / 0.2;
      if (t > 0.8) opacity = (1.0 - t) / 0.2;
      
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawRealisticLightning(Canvas canvas, Size size) {
    // Make lightning strike randomly and rapidly
    final flashCycle = (time * 15) % 1.0; 
    // Only draw lightning during a very short window of the cycle
    if (flashCycle > 0.85) {
      // Glow under the bolt
      final glowPaint = Paint()
        ..color = const Color(0xFFEAB308).withValues(alpha: 0.6)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      // Bright white/yellow core
      final corePaint = Paint()
        ..color = const Color(0xFFFEF08A)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      // Realistic jagged branching path
      final path = Path()
        ..moveTo(size.width * 0.5, size.height * 0.45)
        ..lineTo(size.width * 0.42, size.height * 0.65)
        ..lineTo(size.width * 0.52, size.height * 0.68)
        ..lineTo(size.width * 0.38, size.height * 0.95);
        
      // Branch
      final branch = Path()
        ..moveTo(size.width * 0.42, size.height * 0.65)
        ..lineTo(size.width * 0.32, size.height * 0.75);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(branch, glowPaint);
      
      canvas.drawPath(path, corePaint);
      canvas.drawPath(branch, corePaint);
      
      // Screen flash effect (simulating lighting up the clouds)
      final flashOpacity = (flashCycle - 0.85) / 0.15; // 0 to 1
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 
        size.width * 0.6, 
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15 * flashOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) => true;
}
