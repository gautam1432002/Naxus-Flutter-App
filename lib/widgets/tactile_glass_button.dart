import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TactileGlassButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const TactileGlassButton({
    super.key, 
    required this.icon, 
    required this.onTap,
    this.iconColor,
  });

  @override
  State<TactileGlassButton> createState() => _TactileGlassButtonState();
}

class _TactileGlassButtonState extends State<TactileGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.all(8.0),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: CustomPaint(
                painter: _GradientRimPainter(),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ?? Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a specular gradient rim border on a circle.
class _GradientRimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.40),
          Color.fromRGBO(255, 255, 255, 0.10),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(rect.deflate(0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
