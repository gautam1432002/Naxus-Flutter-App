import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FrostedBackButton extends StatefulWidget {
  final String heroTag;
  final VoidCallback? onTap;

  const FrostedBackButton({
    super.key,
    required this.heroTag,
    this.onTap,
  });

  @override
  State<FrostedBackButton> createState() => _FrostedBackButtonState();
}

class _FrostedBackButtonState extends State<FrostedBackButton> {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _scale = 0.90);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 44,
                height: 44,
                color: Colors.black.withValues(alpha: 0.3),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
