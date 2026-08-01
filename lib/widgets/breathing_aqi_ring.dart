import 'package:flutter/material.dart';

class BreathingAqiRing extends StatefulWidget {
  final double aqiVal;
  final Widget child;

  const BreathingAqiRing({super.key, required this.aqiVal, required this.child});

  @override
  State<BreathingAqiRing> createState() => _BreathingAqiRingState();
}

class _BreathingAqiRingState extends State<BreathingAqiRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _updateSpeed();
  }

  @override
  void didUpdateWidget(BreathingAqiRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aqiVal != widget.aqiVal) {
      _updateSpeed();
    }
  }

  void _updateSpeed() {
    // 0-33 = Good (Slow breathing: ~3 seconds)
    // 66-100 = Hazardous (Fast pulse: ~0.8 seconds)
    int durationMs = 3000;
    if (widget.aqiVal > 66) {
      durationMs = 800;
    } else if (widget.aqiVal > 33) {
      durationMs = 1500;
    }
    
    _controller.duration = Duration(milliseconds: durationMs);
    _controller.repeat(reverse: true);
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
        final scale = 1.0 + (_controller.value * 0.08); // Pulse up to 8%
        return Transform.scale(
          scale: scale,
          child: widget.child,
        );
      },
    );
  }
}
