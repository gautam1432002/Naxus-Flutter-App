import 'package:flutter/material.dart';

class CardFlipRoute<T> extends PageRouteBuilder<T> {
  final String heroTag;

  CardFlipRoute({
    required WidgetBuilder pageBuilder,
    required this.heroTag,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
          transitionDuration: const Duration(milliseconds: 750),
          reverseTransitionDuration: const Duration(milliseconds: 750),
          opaque: true,
          barrierDismissible: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Non-snappy, relaxed easing
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );

            // Angle animates from ~0.35 (20 degrees) down to 0
            // On open: starts at 0.35 (rotated right) and goes to 0 (flat).
            // On close: goes from 0 to 0.35.
            final angleTween = Tween<double>(begin: 0.35, end: 0.0);
            final currentAngle = angleTween.evaluate(curvedAnimation);

            // Apply 3D perspective and rotation
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(currentAngle);

            // Fade in the non-Hero content slightly after flip begins
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
            );

            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}
