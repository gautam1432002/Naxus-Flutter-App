import 'dart:ui';
import 'package:flutter/material.dart';

class GlassConfig {
  // MASTER SWITCH: Turn false to instantly disable all blur for performance testing
  static const bool enableBlur = true; 
  
  // GLOBAL GLASS TWEAKS
  static const double blurSigma = 20.0;
  static final Color overlayColor = Colors.white.withValues(alpha: 0.10);
  static final Color borderColor = Colors.white.withValues(alpha: 0.08);
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  
  // Optional overrides
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
    final bg = overlayColor ?? GlassConfig.overlayColor;
    final border = borderColor ?? GlassConfig.borderColor;

    Widget innerContainer = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1.0),
      ),
      child: child,
    );

    Widget clippedGlass = GlassConfig.enableBlur
        ? ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: innerContainer,
            ),
          )
        : ClipRRect(
            borderRadius: radius,
            child: innerContainer,
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: clippedGlass,
    );
  }
}
