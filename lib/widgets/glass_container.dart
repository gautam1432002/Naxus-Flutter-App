import 'dart:ui';
import 'package:flutter/material.dart';

class GlassConfig {
  /// Master switch:
  /// true  = real BackdropFilter glass
  /// false = fake/gradient glass (better performance)
  static const bool enableBlur = false; // Enabled to allow real glass effects

  // ==========================================
  // BLUR CONFIGURATIONS (BackdropFilter values)
  // ==========================================
  
  /// 1. Unified Header Buttons (Back Button, Action Buttons)
  /// Used in FrostedBackButton and TactileGlassButton.
  /// Modifying this changes all universal header buttons across the app.
  /// Lower values are better for performance. Default: 8.0
  static const double headerBlurSigmaX = 8.0;
  static const double headerBlurSigmaY = 8.0;

  /// 2. Cosmic Lens "Explore Article" panel
  /// Used in the DraggableScrollableSheet in ApodHeroCard.
  /// Since this is a large scrolling panel, keep blur moderate (8.0 - 12.0)
  /// to avoid dropping frames while scrolling the article text. Default: 12.0
  static const double articlePanelBlurSigmaX = 12.0;
  static const double articlePanelBlurSigmaY = 12.0;

  /// 3. Orbit Watch Information Bento Cards (Lat, Lng, Alt, Vel)
  /// Used in orbit_watch_screen.dart (_buildInfoCard).
  /// These are static cards, so a slightly higher blur is fine. Default: 16.0
  static const double orbitWatchCardsBlurSigmaX = 16.0;
  static const double orbitWatchCardsBlurSigmaY = 16.0;

  // ==========================================
  // GENERAL GLASS SETTINGS
  // ==========================================
  
  /// Global default blur intensity fallback
  static const double defaultBlurSigma = 5.0;

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

  /// Optional blur overrides.
  /// If provided, these override the GlassConfig values.
  final double? blurSigmaX;
  final double? blurSigmaY;
  
  // Deprecated: use blurSigmaX and blurSigmaY
  final double? blurSigma;

  final Color? overlayColor;
  final Color? borderColor;
  
  /// Force Real Glass Mode regardless of GlassConfig.enableBlur
  final bool forceRealGlass;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.blurSigmaX,
    this.blurSigmaY,
    this.blurSigma,
    this.overlayColor,
    this.borderColor,
    this.forceRealGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    final sigmaX = blurSigmaX ?? blurSigma ?? GlassConfig.defaultBlurSigma;
    final sigmaY = blurSigmaY ?? blurSigma ?? GlassConfig.defaultBlurSigma;

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
    if (GlassConfig.enableBlur || forceRealGlass) {
      glass = RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sigmaX,
              sigmaY: sigmaY,
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