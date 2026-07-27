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
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.all(8.0),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
    );
  }
}
