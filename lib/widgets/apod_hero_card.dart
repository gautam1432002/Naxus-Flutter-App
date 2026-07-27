import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import 'fullscreen_image_viewer.dart';
import 'apod_video_player.dart';
import 'package:animations/animations.dart';

class ApodHeroCard extends StatelessWidget {
  final ApodModel apod;
  final bool isLive;
  final String heroTag;

  const ApodHeroCard({
    super.key,
    required this.apod,
    this.isLive = false,
    required this.heroTag,
  });

  void _openArticle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.6, 0.95],
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.55),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(28),
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          apod.formattedDate,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        apod.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        apod.explanation,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 17,
                          height: 1.7,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Stack(
          children: [
            // Image / Video Content
            if (apod.mediaType == 'video')
              Positioned.fill(child: ApodVideoPlayer(videoUrl: apod.url))
            else
              Positioned.fill(
                child: OpenContainer(
                  tappable: false,
                  transitionType: ContainerTransitionType.fade,
                  transitionDuration: const Duration(milliseconds: 600),
                  openColor: Colors.transparent,
                  closedColor: Colors.transparent,
                  closedElevation: 0,
                  openElevation: 0,
                  openBuilder: (context, _) => FullscreenImageViewer(
                    imageUrl: apod.url,
                    heroTag: heroTag,
                  ),
                  closedBuilder: (context, openContainer) => GestureDetector(
                    onLongPress: openContainer,
                    child: Hero(
                      tag: heroTag,
                      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: toHeroContext.widget,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: Image.network(
                          apod.url,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: child,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Gradient Scrim
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 250,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, const Color(0xFF0A0A0C).withValues(alpha: 0.95)],
                    ),
                  ),
                ),
              ),
            ),
            
            // Top Badges
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  apod.date,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            
            if (isLive)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8B5CF6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Text Content
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apod.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    apod.explanation,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _openArticle(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Explore Article →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
