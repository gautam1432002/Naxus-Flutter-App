import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeatherParticleSystem extends StatefulWidget {
  final String conditionLabel;

  const WeatherParticleSystem({super.key, required this.conditionLabel});

  @override
  State<WeatherParticleSystem> createState() => _WeatherParticleSystemState();
}

class _WeatherParticleSystemState extends State<WeatherParticleSystem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _initParticles();
  }

  @override
  void didUpdateWidget(WeatherParticleSystem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conditionLabel != widget.conditionLabel) {
      _initParticles();
    }
  }

  void _initParticles() {
    _particles.clear();
    final String condition = widget.conditionLabel.toLowerCase();
    int count = 0;
    
    if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('storm') || condition.contains('thunder')) {
      count = 80;
    } else if (condition.contains('snow')) {
      count = 60;
    } else {
      count = 35; // Ambient dust
    }

    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: _random.nextDouble() * 0.5 + 0.1,
        size: _random.nextDouble() * 3 + 1,
        offset: _random.nextDouble() * math.pi * 2,
      ));
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
          painter: _ParticlePainter(
            particles: _particles,
            condition: widget.conditionLabel.toLowerCase(),
            time: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double offset;

  _Particle({required this.x, required this.y, required this.speed, required this.size, required this.offset});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final String condition;
  final double time;

  _ParticlePainter({required this.particles, required this.condition, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final bool isRain = condition.contains('rain') || condition.contains('drizzle') || condition.contains('storm');
    final bool isSnow = condition.contains('snow');

    final paint = Paint();

    if (isRain) {
      paint.color = Colors.white.withValues(alpha: 0.4);
      paint.strokeWidth = 1.5;
      paint.strokeCap = StrokeCap.round;
    } else if (isSnow) {
      paint.color = Colors.white.withValues(alpha: 0.6);
      paint.style = PaintingStyle.fill;
    } else {
      // Ambient dust
      paint.color = const Color(0xFFFDE047).withValues(alpha: 0.15); // Warm glow
      paint.style = PaintingStyle.fill;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    }

    for (var p in particles) {
      if (isRain) {
        // Falling fast, angled
        double y = (p.y + (time * p.speed * 20)) % 1.0;
        double x = (p.x + (y * 0.15)) % 1.0; // slight wind
        
        canvas.drawLine(
          Offset(x * size.width, y * size.height),
          Offset((x + 0.015) * size.width, (y + 0.04) * size.height),
          paint,
        );
      } else if (isSnow) {
        // Drifting down, swaying
        double y = (p.y + (time * p.speed * 2)) % 1.0;
        double x = (p.x + math.sin(time * math.pi * 4 + p.offset) * 0.05) % 1.0;
        if (x < 0) x += 1.0;
        
        canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, paint);
      } else {
        // Ambient dust drifting slowly upward
        double y = (p.y - (time * p.speed * 0.5)) % 1.0;
        if (y < 0) y += 1.0;
        double x = (p.x + math.sin(time * math.pi * 2 + p.offset) * 0.02) % 1.0;
        if (x < 0) x += 1.0;
        
        canvas.drawCircle(Offset(x * size.width, y * size.height), p.size * 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
