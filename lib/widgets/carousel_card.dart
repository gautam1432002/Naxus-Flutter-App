import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class CardThemeInfo {
  final Color primaryColor;
  final IconData icon;
  final String badgeText;
  final String title;
  final String description;
  final IconData previewIcon;
  final String previewText;
  final String actionHint;
  final VoidCallback onTap;

  const CardThemeInfo({
    required this.primaryColor,
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.previewIcon,
    required this.previewText,
    required this.actionHint,
    required this.onTap,
  });
}

class CarouselCard extends StatelessWidget {
  final CardThemeInfo info;
  final double diff;

  const CarouselCard({super.key, required this.info, this.diff = 0.0});

  @override
  Widget build(BuildContext context) {
    // Determine how "active" (centered) this card is. 
    // 0.0 = perfectly centered, 1.0 = adjacent card
    final double activeFocus = (1.0 - diff.abs()).clamp(0.0, 1.0);
    
    // Swipe Shimmer logic
    // Maps the diff to a horizontal alignment so the highlight drags across the surface.
    final shimmerAlignmentX = diff.clamp(-1.0, 1.0) * -2.0; 
    
    // Blur effect when swiping or in rest position (clears when centered)
    final double blurSigma = (1.0 - activeFocus) * 5.0; // Max blur of 5.0 when peripheral

    return GestureDetector(
      onTap: info.onTap,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Outer Glow
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: info.primaryColor.withValues(alpha: 0.35 * activeFocus), // Only glow when active
                    blurRadius: 100 * activeFocus,
                    spreadRadius: 20 * activeFocus,
                  ),
                ],
              ),
            ),
          ),
          // Main Liquid Glass Card
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: info.primaryColor.withValues(alpha: 0.1 + (0.15 * activeFocus)), // Fully filled colored glass effect
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15 + (0.2 * activeFocus)),
                    width: 0.5, // Thinner, elegant border
                  ),
                ),
                child: Stack(
                  children: [
                    // Inner Top Reflection
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 275, // 55% of 500
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom Theme Glow
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 375, // 75% of 500
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              info.primaryColor.withValues(alpha: 0.3 + (0.4 * activeFocus)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Frosted Swipe Shimmer overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(shimmerAlignmentX - 0.5, -0.5),
                            end: Alignment(shimmerAlignmentX + 0.5, 0.5),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.2 * (1.0 - activeFocus)), // Shimmer peaks during swipe
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Solid 3D HUD Watermark
                    Center(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002) // Perspective
                          ..rotateX(diff * pi / 3) // Rotates vertically based on swipe
                          ..rotateY(-diff * pi / 2.5) // Rotates horizontally
                          ..rotateZ(diff * pi / 4) // Spins as it moves
                          ..scale(0.5 + 0.5 * activeFocus), // Scales up in the center
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1), // Elegant, low opacity
                              width: 1, // Delicate stroke
                            ),
                          ),
                          child: Center(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateZ(-diff * pi), // Inner ring spins opposite direction
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15), // Elegant, crisp thin border
                                    width: 1, // Delicate stroke
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: info.primaryColor.withValues(alpha: 0.2), // Soft, subtle ambient glow
                                      blurRadius: 40,
                                    ),
                                  ]
                                ),
                                child: Center(
                                  child: Icon(
                                    info.icon,
                                    size: 60,
                                    color: Colors.white.withValues(alpha: 0.25), // Subtle UI-driven watermark opacity
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Card Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row (Icon + Badge)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Icon(info.icon, color: Colors.white.withValues(alpha: 0.95), size: 28),
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (info.badgeText == 'Live') ...[
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                              boxShadow: const [
                                                BoxShadow(color: Colors.redAccent, blurRadius: 12)
                                              ]
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          info.badgeText.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Text Body
                          Text(
                            info.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            info.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                              height: 1.6,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          // Footer
                          Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(info.previewIcon, size: 12, color: Colors.white.withValues(alpha: 0.45)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          info.previewText,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.45),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(40),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                                      ),
                                      child: Text(
                                        info.actionHint,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
