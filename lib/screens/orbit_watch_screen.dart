import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/iss_model.dart';
import '../services/iss_service.dart';
import '../services/connectivity_service.dart';

import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/tactile_glass_button.dart';
import '../services/app_data_store.dart';
import 'fullscreen_map_screen.dart';

class OrbitWatchScreen extends StatefulWidget {
  const OrbitWatchScreen({super.key});

  @override
  State<OrbitWatchScreen> createState() => _OrbitWatchScreenState();
}

class _OrbitWatchScreenState extends State<OrbitWatchScreen> with TickerProviderStateMixin {
  final IssService _issService = IssService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final MapController _mapController = MapController();
  
  IssModel? _issPosition;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  AnimationController? _mapAnimationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initFetch();
  }

  Future<void> _initFetch() async {
    final store = AppDataStore();
    if (store.issPosition != null) {
      if (mounted) {
        setState(() {
          _issPosition = store.issPosition;
          _isLoading = false;
        });
      }
    }
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) {
      if (mounted) {
        setState(() {
          _error = 'No internet connection';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final pos = await _issService.fetchIssPosition();
      if (mounted) {
        setState(() {
          _issPosition = pos;
          _isLoading = false;
        });
        
        // Start periodic polling after successful first fetch
        _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollPosition());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pollPosition() async {
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) return;

    try {
      final pos = await _issService.fetchIssPosition();
      if (mounted) {
        setState(() {
          _issPosition = pos;
        });
        
        // Smoothly recenter map
        _animatedMapMove(LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
      }
    } catch (e) {
      // Silently skip if a periodic refresh fails
      debugPrint('Periodic fetch failed: $e');
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;
    
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom, end: destZoom);

    _mapAnimationController?.dispose();
    _mapAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    final Animation<double> animation =
        CurvedAnimation(parent: _mapAnimationController!, curve: Curves.fastOutSlowIn);

    _mapAnimationController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _mapAnimationController?.dispose();
        _mapAnimationController = null;
      }
    });

    _mapAnimationController!.forward();
  }

  void _loadDataAndCenterMap() {
    _initFetch();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    _mapAnimationController?.dispose();
    super.dispose();
  }

  String _formatLat(double lat) => '${lat.abs().toStringAsFixed(4)}° ${lat >= 0 ? 'N' : 'S'}';
  String _formatLng(double lng) => '${lng.abs().toStringAsFixed(4)}° ${lng >= 0 ? 'E' : 'W'}';

  Widget _buildBentoCell(String label, IconData icon, double value, String Function(double) formatter) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: const Color(0xFF06B6D4)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: value, end: value),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Text(
                      formatter(val),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_issPosition!.latitude, _issPosition!.longitude),
        initialZoom: 3.5,
        minZoom: 2,
        maxZoom: 10,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.nexus',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(_issPosition!.latitude, _issPosition!.longitude),
              width: 60,
              height: 60,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glowing background
                        Container(
                          width: 48 * _pulseAnimation.value,
                          height: 48 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.3 * (1.6 - _pulseAnimation.value)),
                          ),
                        ),
                        // Inner icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF06B6D4), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.satellite_alt,
                            color: Color(0xFF06B6D4),
                            size: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap, © CARTO',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040B16), // Fallback
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceEnvironmentBackground()),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Floating Navigation Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TactileGlassButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      TactileGlassButton(
                        icon: Icons.my_location,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _loadDataAndCenterMap();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Header Title & Status Pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Orbit Watch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      // Live badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF06B6D4).withValues(alpha: _pulseAnimation.value),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF06B6D4).withValues(alpha: _pulseAnimation.value * 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ISS LIVE RELAY',
                              style: TextStyle(
                                color: Color(0xFF06B6D4),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 3D Glass Map Viewport
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GestureDetector(
                      onLongPress: () {
                        if (_issPosition != null) {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 600),
                              reverseTransitionDuration: const Duration(milliseconds: 600),
                              pageBuilder: (context, animation, secondaryAnimation) {
                                return FullscreenMapScreen(issPosition: _issPosition!);
                              },
                            ),
                          );
                        }
                      },
                      child: Hero(
                        tag: 'orbit_map',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: _isLoading 
                                  ? const SkeletonLoader(width: double.infinity, height: double.infinity)
                                  : _error != null 
                                      ? ErrorState(
                                          accentColor: const Color(0xFF06B6D4),
                                          message: _error!,
                                          onRetry: _initFetch,
                                        )
                                      : _buildMap(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bento Telemetry Deck
                if (_issPosition != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildBentoCell('LATITUDE', Icons.explore, _issPosition!.latitude, _formatLat)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildBentoCell('LONGITUDE', Icons.public, _issPosition!.longitude, _formatLng)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildBentoCell('ALTITUDE', Icons.height, _issPosition!.altitude, (val) => '${val.toStringAsFixed(1)} km')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildBentoCell('VELOCITY', Icons.speed, _issPosition!.velocity, (val) => '${val.toStringAsFixed(0)} km/h')),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpaceEnvironmentBackground extends StatefulWidget {
  const SpaceEnvironmentBackground({super.key});

  @override
  State<SpaceEnvironmentBackground> createState() => _SpaceEnvironmentBackgroundState();
}

class _SpaceEnvironmentBackgroundState extends State<SpaceEnvironmentBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final TextPainter _planetPainter;
  late final TextPainter _satellitePainter;
  late final TextPainter _rocketPainter;
  late final TextPainter _cometPainter;
  late final TextPainter _antennaPainter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    
    // Cache TextPainters for performance
    _planetPainter = _createEmojiPainter('🪐', 100);
    _satellitePainter = _createEmojiPainter('🛰️', 32);
    _rocketPainter = _createEmojiPainter('🚀', 36);
    _cometPainter = _createEmojiPainter('☄️', 30);
    _antennaPainter = _createEmojiPainter('📡', 60);
  }

  TextPainter _createEmojiPainter(String emoji, double size) {
    final painter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    return painter;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SpacePainter(
            time: _controller.value,
            planetPainter: _planetPainter,
            satellitePainter: _satellitePainter,
            rocketPainter: _rocketPainter,
            cometPainter: _cometPainter,
            antennaPainter: _antennaPainter,
          ),
          size: Size.infinite,
        );
      }
    );
  }
}

class _SpacePainter extends CustomPainter {
  final double time;
  final TextPainter planetPainter;
  final TextPainter satellitePainter;
  final TextPainter rocketPainter;
  final TextPainter cometPainter;
  final TextPainter antennaPainter;

  _SpacePainter({
    required this.time,
    required this.planetPainter,
    required this.satellitePainter,
    required this.rocketPainter,
    required this.cometPainter,
    required this.antennaPainter,
  });

  void _drawCachedEmoji(Canvas canvas, TextPainter painter, Offset center, [double opacity = 1.0]) {
    if (opacity < 1.0) {
      canvas.saveLayer(
        Rect.fromCenter(center: center, width: painter.width, height: painter.height),
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
      painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
      canvas.restore();
    } else {
      painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, double opacity) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final path = ui.Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Deep cosmic background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          const Color(0xFF040B16),
          const Color(0xFF0B1426),
          const Color(0xFF150B24),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Nebula Accents
    final nebula1 = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 200, nebula1);

    final nebula2 = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 250, nebula2);

    // Planet 🪐
    _drawCachedEmoji(canvas, planetPainter, Offset(size.width * 0.85, size.height * 0.15), 0.6);

    // Custom Sparkle Stars
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final maxOpacity = random.nextDouble() * 0.8 + 0.2;
      final phase = random.nextDouble() * 2 * math.pi;
      
      final currentOpacity = maxOpacity * (0.5 + 0.5 * math.sin(time * math.pi * 10 + phase));
      _drawSparkle(canvas, Offset(x, y), random.nextDouble() * 6 + 4, currentOpacity);
    }
    
    // Normal small dots for background fill
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final currentOpacity = 0.5 * (0.5 + 0.5 * math.sin(time * math.pi * 10 + random.nextDouble() * 2 * math.pi));
      starPaint.color = Colors.white.withValues(alpha: currentOpacity);
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5, starPaint);
    }

    // Space Antenna 📡
    final antennaPos = Offset(size.width * 0.15, size.height * 0.8);
    _drawCachedEmoji(canvas, antennaPainter, antennaPos, 0.9);
    
    // Signals 📶 (Drawn dynamically as it changes)
    final signalPhase = (time * 15) % 1.0;
    if (signalPhase > 0.5) {
      final signalPainter = TextPainter(
        text: TextSpan(text: '📶', style: TextStyle(fontSize: 24, color: Colors.white.withValues(alpha: 0.8))),
        textDirection: TextDirection.ltr,
      )..layout();
      final signalPos = Offset(antennaPos.dx + 30, antennaPos.dy - 30);
      signalPainter.paint(canvas, signalPos - Offset(signalPainter.width / 2, signalPainter.height / 2));
    }

    // Rocket 🚀 (Moves diagonally)
    final rocketProgress = (time * 1.5) % 1.0;
    final rocketX = size.width * -0.2 + (size.width * 1.4 * rocketProgress);
    final rocketY = size.height * 1.2 - (size.height * 1.4 * rocketProgress);
    canvas.save();
    canvas.translate(rocketX, rocketY);
    _drawCachedEmoji(canvas, rocketPainter, Offset.zero);
    canvas.restore();

    // Nebula particles / Shooting Star ☄️
    final cometProgress = (time * 3.0 + 0.5) % 1.0;
    final cometX = size.width * 1.2 - (size.width * 1.4 * cometProgress);
    final cometY = size.height * -0.2 + (size.height * 1.4 * cometProgress);
    canvas.save();
    canvas.translate(cometX, cometY);
    canvas.rotate(math.pi); // Pointing down-left
    _drawCachedEmoji(canvas, cometPainter, Offset.zero);
    canvas.restore();

    // Orbital Paths
    final orbitPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final center = Offset(size.width / 2, size.height * 0.4);
    canvas.drawCircle(center, 160, orbitPaint);
    canvas.drawCircle(center, 240, orbitPaint);

    // Satellites 🛰️
    final angle1 = time * 2 * math.pi;
    final sat1X = center.dx + 160 * math.cos(angle1);
    final sat1Y = center.dy + 160 * math.sin(angle1);
    
    canvas.save();
    canvas.translate(sat1X, sat1Y);
    canvas.rotate(angle1 + math.pi / 2);
    _drawCachedEmoji(canvas, satellitePainter, Offset.zero);
    canvas.restore();
    
    final angle2 = -time * 2 * math.pi * 0.6 + math.pi;
    final sat2X = center.dx + 240 * math.cos(angle2);
    final sat2Y = center.dy + 240 * math.sin(angle2);
    
    canvas.save();
    canvas.translate(sat2X, sat2Y);
    canvas.rotate(angle2 + math.pi / 2);
    // Draw smaller satellite by scaling
    canvas.scale(0.75);
    _drawCachedEmoji(canvas, satellitePainter, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) => time != oldDelegate.time;
}
