import 'dart:ui';
import 'package:flutter/material.dart';

class GlassConfig {
  /// Master switch:
  /// true  = real BackdropFilter glass
  /// false = fake/gradient glass (better performance)
  static const bool enableBlur = false;

  /// Real blur intensity when enableBlur = true.
  static const double blurSigma = 5.0;

  /// Transparent white glass tint.
  static const double glassOpacity = 0.10;

  /// Subtle glass border.
  static const double borderOpacity = 0.08;

  /// Soft depth shadow.
  static const double shadowOpacity = 0.10;
  static const double shadowBlur = 15.0;
}

class GlassContainer extends StatelessWidget {
  final Widget child;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Optional overrides.
  final double? blurSigma;
  final Color? overlayColor;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.blurSigma,
    this.overlayColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    final sigma = blurSigma ?? GlassConfig.blurSigma;

    final glassColor = overlayColor ??
        Colors.white.withValues(
          alpha: GlassConfig.glassOpacity,
        );

    final glassBorder = borderColor ??
        Colors.white.withValues(
          alpha: GlassConfig.borderOpacity,
        );

    final innerContent = Container(
      width: width,
      height: height,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,

        // Transparent white surface.
        color: glassColor,

        border: Border.all(
          color: glassBorder,
          width: 1.0,
        ),
      ),
      child: child,
    );

    Widget glass;

    // ============================================================
    // REAL GLASS MODE
    // ============================================================
    if (GlassConfig.enableBlur) {
      glass = RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
            ),
            child: innerContent,
          ),
        ),
      );
    }

    // ============================================================
    // FAKE GLASS MODE
    // ============================================================
    else {
      glass = ClipRRect(
        borderRadius: radius,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: radius,

            // No BackdropFilter here.
            // Transparent gradient simulates frosted glass.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.03),
                Colors.white.withValues(alpha: 0.07),
              ],
              stops: const [
                0.0,
                0.45,
                1.0,
              ],
            ),

            border: Border.all(
              color: glassBorder,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      );
    }

    // ============================================================
    // DEPTH / SHADOW
    // ============================================================

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: GlassConfig.shadowOpacity,
            ),
            blurRadius: GlassConfig.shadowBlur,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: glass,
    );
  }
}