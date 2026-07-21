import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedBackButton extends StatelessWidget {
  final String heroTag;
  final VoidCallback? onTap;

  const FrostedBackButton({
    super.key,
    required this.heroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 44,
            height: 44,
            color: Colors.black.withValues(alpha: 0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: onTap ?? () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}
