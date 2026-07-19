import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../widgets/carousel_card.dart';
import 'cosmic_lens_screen.dart';
import 'echoes_screen.dart';
import 'air_pulse_screen.dart';
import 'orbit_watch_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 0.65 fraction accurately matches the hit-test areas for the side cards
    _pageController = PageController(viewportFraction: 0.65);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPlaceholder(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PlaceholderScreen(title: title),
      ),
    );
  }

  List<CardThemeInfo> get _cards => [
    CardThemeInfo(
      primaryColor: const Color(0xFF8B5CF6),
      icon: Icons.rocket_launch,
      badgeText: 'Today',
      title: 'Cosmic Lens',
      description: 'Daily space imagery and explanations from the cosmos.',
      previewIcon: Icons.star,
      previewText: 'Pillars of Creation',
      actionHint: 'NASA',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CosmicLensScreen()),
      ),
    ),
    CardThemeInfo(
      primaryColor: const Color(0xFFFBBF24),
      icon: Icons.satellite_alt,
      badgeText: 'Live',
      title: 'Orbit Watch',
      description: 'Real-time position and telemetry of the space station.',
      previewIcon: Icons.location_on,
      previewText: '45.2°N · 75.6°W',
      actionHint: 'Live Feed',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OrbitWatchScreen()),
      ),
    ),
    CardThemeInfo(
      primaryColor: const Color(0xFFEC4899),
      icon: Icons.cloud,
      badgeText: 'AQI 48',
      title: 'Air Pulse',
      description: 'Air quality, forecasts, and weather statistics.',
      previewIcon: Icons.thermostat,
      previewText: '22°C · Good',
      actionHint: 'Real-time',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AirPulseScreen()),
      ),
    ),
    CardThemeInfo(
      primaryColor: const Color(0xFF06B6D4),
      icon: Icons.menu_book,
      badgeText: 'Today',
      title: 'Echoes',
      description: 'Historical events, births, and notable deaths.',
      previewIcon: Icons.calendar_today,
      previewText: 'Jul 16',
      actionHint: 'Daily',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EchoesScreen()),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.spaceBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Static Starfield Background
            Positioned.fill(
              child: CustomPaint(
                painter: StarfieldPainter(),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3D Carousel Implementation
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // BOTTOM LAYER: Explicitly rendered, depth-sorted 3D cards
                      AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double page = 0.0;
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                            page = _pageController.page ?? 0.0;
                          }

                          List<Map<String, dynamic>> cardRenders = [];
                          for (int i = 0; i < _cards.length; i++) {
                            double diff = i - page;
                            cardRenders.add({
                              'index': i,
                              'diff': diff,
                              'absDiff': diff.abs(),
                            });
                          }

                          // Sort by absolute diff descending (furthest cards drawn first)
                          cardRenders.sort((a, b) => b['absDiff'].compareTo(a['absDiff']));

                          return Stack(
                            alignment: Alignment.center,
                            children: cardRenders.map((render) {
                              int index = render['index'];
                              double diff = render['diff'];
                              
                              double rotateY = 0;
                              double scale = 1.0;
                              double opacity = 1.0;
                              double translationX = 0;

                              if (diff.abs() < 0.001) {
                                scale = 1.0;
                                opacity = 1.0;
                                rotateY = 0;
                                translationX = 0;
                              } else if (diff.abs() <= 1.001) {
                                scale = 1.0 - (0.15 * diff.abs()); 
                                opacity = 1.0 - (0.4 * diff.abs()); 
                                rotateY = -8 * diff * (pi / 180); 
                                translationX = 130 * diff; 
                              } else if (diff.abs() <= 2.001) {
                                scale = 0.85 - (0.15 * (diff.abs() - 1)); 
                                opacity = 0.6 - (0.3 * (diff.abs() - 1)); 
                                rotateY = -12 * diff.sign * (pi / 180);
                                translationX = (130 + 100 * (diff.abs() - 1)) * diff.sign;
                              } else {
                                scale = 0.5;
                                opacity = 0.0;
                                translationX = 0;
                              }

                              final Matrix4 transform = Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // perspective
                                ..translate(translationX, 0.0, 0.0)
                                ..rotateY(rotateY)
                                ..scale(scale);

                              return Transform(
                                transform: transform,
                                alignment: Alignment.center,
                                child: Opacity(
                                  opacity: opacity.clamp(0.0, 1.0),
                                  child: SizedBox(
                                    width: 340,
                                    height: 500,
                                    // Ignore pointers on the visual layer so the top PageView catches gestures
                                    child: IgnorePointer(
                                      child: CarouselCard(info: _cards[index]),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      // TOP LAYER: Invisible PageView for gesture capture and physics
                      Positioned.fill(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              // Ensure transparent areas catch the tap/swipe
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                // If clicked the centered card, trigger action
                                if (_pageController.page?.round() == index) {
                                  _cards[index].onTap();
                                } else {
                                  // If clicked a side card, animate to it
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                              child: Container(color: Colors.transparent),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); 
    final paint = Paint()..color = Colors.white.withOpacity(0.3);

    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.4 + 0.1);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.spaceBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Text(
            '$title Service',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
