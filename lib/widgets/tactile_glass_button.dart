import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'glass_container.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 48,
            height: 48,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              child: Center(
                child: Icon(
                      widget.icon,
                      color: widget.iconColor ?? Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

