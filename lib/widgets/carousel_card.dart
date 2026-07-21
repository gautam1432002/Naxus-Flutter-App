import 'dart:ui';
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

  const CarouselCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: info.onTap,
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
                    color: info.primaryColor.withValues(alpha: 0.4), // Softer in Flutter compared to CSS
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Main Liquid Glass Card
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0C18).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: info.primaryColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 60,
                      offset: const Offset(0, 30),
                    ),
                  ],
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
                              info.primaryColor.withValues(alpha: 0.55),
                            ],
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
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: info.primaryColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: info.primaryColor.withValues(alpha: 0.35),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    )
                                  ]
                                ),
                                child: Icon(info.icon, color: info.primaryColor.withValues(alpha: 0.9), size: 28),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(color: info.primaryColor.withValues(alpha: 0.3)),
                                  color: info.primaryColor.withValues(alpha: 0.25),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (info.badgeText == 'Live') ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: info.primaryColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: info.primaryColor, blurRadius: 12)
                                          ]
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      info.badgeText.toUpperCase(),
                                      style: TextStyle(
                                        color: info.primaryColor.withValues(alpha: 0.9),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
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
                                Row(
                                  children: [
                                    Icon(info.previewIcon, size: 12, color: Colors.white.withValues(alpha: 0.45)),
                                    const SizedBox(width: 6),
                                    Text(
                                      info.previewText,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                  ),
                                  child: Text(
                                    info.actionHint,
                                    style: TextStyle(
                                      color: info.primaryColor.withValues(alpha: 0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
    );
  }
}
