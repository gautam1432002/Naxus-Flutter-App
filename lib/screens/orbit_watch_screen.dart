import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/iss_model.dart';
import '../services/iss_service.dart';

import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/tactile_glass_button.dart';
import '../widgets/nexus_universal_header.dart';
import '../services/app_data_store.dart';
import 'fullscreen_map_screen.dart';

class OrbitWatchScreen extends StatefulWidget {
  const OrbitWatchScreen({super.key});

  @override
  State<OrbitWatchScreen> createState() => _OrbitWatchScreenState();
}

class _OrbitWatchScreenState extends State<OrbitWatchScreen> with TickerProviderStateMixin {
  final IssService _issService = IssService();
  final MapController _mapController = MapController();
  
  IssModel? _issPosition;
  double _issHeading = 90.0; // Default to East
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  AnimationController? _mapAnimationController;

  bool _isReconnecting = false;
  bool _isOffline = false;

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final l1 = lat1 * math.pi / 180.0;
    final l2 = lat2 * math.pi / 180.0;
    final y = math.sin(dLon) * math.cos(l2);
    final x = math.cos(l1) * math.sin(l2) - math.sin(l1) * math.cos(l2) * math.cos(dLon);
    return (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
  }
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

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
    try {
      final positionsResult = await _issService.fetchInitialPositions();
      final positions = positionsResult.data;
      if (mounted && positions.isNotEmpty) {
        final pos = positions.last;
        final pastPos = positions.first;
        
        setState(() {
          if (positions.length > 1) {
            _issHeading = _calculateBearing(pastPos.latitude, pastPos.longitude, pos.latitude, pos.longitude);
          }
          _issPosition = pos;
          _isOffline = positionsResult.isOffline;
          _isReconnecting = _isOffline;
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
    try {
      final posResult = await _issService.fetchIssPosition();
      final pos = posResult.data;
      if (mounted) {
        setState(() {
          if (_issPosition != null) {
            _issHeading = _calculateBearing(_issPosition!.latitude, _issPosition!.longitude, pos.latitude, pos.longitude);
          }
          _issPosition = pos;
          _isOffline = posResult.isOffline;
          _isReconnecting = _isOffline;
        });
        
        // Smoothly recenter map
        _animatedMapMove(LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
      }
    } catch (e) {
      // Gracefully degrade: keep last known position but show reconnecting state
      if (mounted && !_isReconnecting) {
        setState(() => _isReconnecting = true);
      }
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
        boxShadow: AppTheme.bentoShadow,
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
            if (_issPosition != null)
              Marker(
                point: LatLng(_issPosition!.latitude, _issPosition!.longitude),
                width: 60,
                height: 60,
                child: _MiniatureISSMarker(heading: _issHeading),
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
          
          // Full Screen Scrollable Content
          CustomScrollView(
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: const SliverToBoxAdapter(
                  child: SizedBox(height: 72), // Space for floating navigation row
                ),
              ),
              
              // Header Title & Status Pill
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        sliver: SliverToBoxAdapter(
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
                                    Text(
                                      _isReconnecting ? 'RECONNECTING...' : 'ISS LIVE RELAY',
                                      style: TextStyle(
                                        color: _isReconnecting ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4),
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
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      
                      // Map Viewport (Hero)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 400,
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
                                    border: Border.all(
                                      color: (_isReconnecting ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4)).withValues(alpha: 0.3), 
                                      width: 1.5,
                                    ),
                                    boxShadow: AppTheme.bentoShadow,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(36),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                      child: _isLoading 
                                          ? const SkeletonLoader(width: double.infinity, height: double.infinity)
                                          : _error != null && _issPosition == null
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
                      ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      
                      // Telemetry Deck
                      if (_issPosition != null)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
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
                            ]),
                          ),
                        ),
                    ],
                  ),
          
          // Floating Navigation Row (Universal)
          NexusUniversalHeader(
            onBack: () => Navigator.of(context).pop(),
            actions: [
              if (_isOffline)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.cloud_off, color: Color(0xFFE11D48), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'OFFLINE',
                        style: TextStyle(
                          color: Color(0xFFE11D48),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
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
          painter: _SpacePainter(time: _controller.value),
          size: Size.infinite,
        );
      }
    );
  }
}

class _SpacePainter extends CustomPainter {
  final double time;

  _SpacePainter({required this.time});

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

  void _drawSatellite(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    
    final bodyPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final panelPaint = Paint()..color = const Color(0xFF06B6D4).withValues(alpha: 0.6);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Solar panels
    canvas.drawRect(Rect.fromCenter(center: const Offset(-15, 0), width: 12, height: 8), panelPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(15, 0), width: 12, height: 8), panelPaint);
    
    // Truss/Connection
    canvas.drawLine(const Offset(-15, 0), const Offset(15, 0), linePaint);
    
    // Main Body
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 12), bodyPaint);
    
    // Antenna dish
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, 8), width: 10, height: 10),
      0, math.pi, false, linePaint..strokeWidth = 1.5
    );
    canvas.restore();
  }

  void _drawRocket(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final bodyPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final windowPaint = Paint()..color = const Color(0xFF06B6D4);
    final flamePaint = Paint()
      ..shader = ui.Gradient.radial(const Offset(0, 15), 10, [
        const Color(0xFFF59E0B),
        const Color(0xFFF59E0B).withValues(alpha: 0.0)
      ]);

    // Body
    final path = ui.Path();
    path.moveTo(0, -15); // Nose
    path.lineTo(6, -5);
    path.lineTo(6, 10);
    path.lineTo(-6, 10);
    path.lineTo(-6, -5);
    path.close();
    canvas.drawPath(path, bodyPaint);

    // Fins
    final finPath = ui.Path();
    finPath.moveTo(6, 5);
    finPath.lineTo(12, 12);
    finPath.lineTo(6, 12);
    finPath.close();
    finPath.moveTo(-6, 5);
    finPath.lineTo(-12, 12);
    finPath.lineTo(-6, 12);
    finPath.close();
    canvas.drawPath(finPath, bodyPaint);

    // Window
    canvas.drawCircle(const Offset(0, -2), 2.5, windowPaint);

    // Flame
    canvas.drawCircle(const Offset(0, 15), 8 + 2 * math.sin(time * 50), flamePaint);

    canvas.restore();
  }

  void _drawAntenna(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final bodyPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Base
    canvas.drawLine(const Offset(0, 0), const Offset(0, 15), linePaint);
    canvas.drawLine(const Offset(-10, 15), const Offset(10, 15), linePaint);
    
    // Dish
    final dishPath = ui.Path();
    dishPath.moveTo(-15, -5);
    dishPath.quadraticBezierTo(0, 10, 15, -5);
    canvas.drawPath(dishPath, linePaint);

    // Receiver
    canvas.drawLine(const Offset(0, 0), const Offset(0, -10), linePaint..strokeWidth = 1.0);
    canvas.drawCircle(const Offset(0, -10), 2, bodyPaint);

    // Signals
    final signalPhase = (time * 15) % 1.0;
    if (signalPhase > 0.5) {
      final signalPaint = Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(Rect.fromCenter(center: const Offset(0, -10), width: 16, height: 16), -math.pi * 0.75, math.pi * 0.5, false, signalPaint);
      canvas.drawArc(Rect.fromCenter(center: const Offset(0, -10), width: 24, height: 24), -math.pi * 0.75, math.pi * 0.5, false, signalPaint);
    }

    canvas.restore();
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

    // Planet
    final planetPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.85, size.height * 0.15),
        40,
        [const Color(0xFF334155), const Color(0xFF0F172A)],
      );
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 40, planetPaint);
    
    // Planet Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.save();
    canvas.translate(size.width * 0.85, size.height * 0.15);
    canvas.rotate(math.pi * 0.2);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 120, height: 30), ringPaint);
    canvas.restore();

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

    // Space Antenna
    _drawAntenna(canvas, Offset(size.width * 0.15, size.height * 0.8));

    // Rocket (Moves diagonally)
    final rocketProgress = (time * 1.5) % 1.0;
    final rocketX = size.width * -0.2 + (size.width * 1.4 * rocketProgress);
    final rocketY = size.height * 1.2 - (size.height * 1.4 * rocketProgress);
    _drawRocket(canvas, Offset(rocketX, rocketY), math.pi * 0.25);

    // Shooting Star
    final cometProgress = (time * 3.0 + 0.5) % 1.0;
    final cometX = size.width * 1.2 - (size.width * 1.4 * cometProgress);
    final cometY = size.height * -0.2 + (size.height * 1.4 * cometProgress);
    final cometPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cometX, cometY),
        Offset(cometX + 60, cometY - 60),
        [Colors.white, Colors.white.withValues(alpha: 0.0)],
      )
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cometX, cometY), Offset(cometX + 60, cometY - 60), cometPaint);
    canvas.drawCircle(Offset(cometX, cometY), 2.0, Paint()..color = Colors.white);

    // Orbital Paths
    final orbitPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final center = Offset(size.width / 2, size.height * 0.4);
    canvas.drawCircle(center, 160, orbitPaint);
    canvas.drawCircle(center, 240, orbitPaint);

    // Satellites
    final angle1 = time * 2 * math.pi;
    final sat1X = center.dx + 160 * math.cos(angle1);
    final sat1Y = center.dy + 160 * math.sin(angle1);
    _drawSatellite(canvas, Offset(sat1X, sat1Y), angle1 + math.pi / 2);
    
    final angle2 = -time * 2 * math.pi * 0.6 + math.pi;
    final sat2X = center.dx + 240 * math.cos(angle2);
    final sat2Y = center.dy + 240 * math.sin(angle2);
    _drawSatellite(canvas, Offset(sat2X, sat2Y), angle2 + math.pi / 2);
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) => time != oldDelegate.time;
}

class _MiniatureISSMarker extends StatefulWidget {
  final double heading;
  const _MiniatureISSMarker({required this.heading});

  @override
  State<_MiniatureISSMarker> createState() => _MiniatureISSMarkerState();
}

class _MiniatureISSMarkerState extends State<_MiniatureISSMarker> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple animation
        AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return Container(
              width: 60 * _rippleController.value,
              height: 60 * _rippleController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 1.0 - _rippleController.value),
                  width: 2,
                ),
                color: Colors.grey.withValues(alpha: (1.0 - _rippleController.value) * 0.2),
              ),
            );
          },
        ),
        // ISS CustomPaint
        CustomPaint(
          size: const Size(60, 60),
          painter: _ISSPainter(heading: widget.heading),
        ),
      ],
    );
  }
}

class _ISSPainter extends CustomPainter {
  final double heading;
  _ISSPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Rotate canvas based on the heading.
    // The nose of the station points to the left (-X).
    // Rotating by (heading + 90) aligns -X with the correct compass bearing.
    canvas.rotate((heading + 90) * math.pi / 180.0);

    // Hard drop shadow (bottom-right offset)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    
    // Draw shadow first by shifting
    canvas.save();
    canvas.translate(2, 3);
    _drawStationShapes(canvas, shadowPaint);
    canvas.restore();

    // Now draw the actual colored station
    _drawStationShapes(canvas, null);

    canvas.restore();
  }

  void _drawStationShapes(Canvas canvas, Paint? overridePaint) {
    // Materials
    final greyPaint = overridePaint ?? (Paint()..color = const Color(0xFF9CA3AF));
    final lightGreyPaint = overridePaint ?? (Paint()..color = const Color(0xFFE5E7EB));
    final darkGreyPaint = overridePaint ?? (Paint()..color = const Color(0xFF6B7280));
    final goldPaint = overridePaint ?? (Paint()..color = const Color(0xFFD97706));
    final solarPaint = overridePaint ?? (Paint()..color = const Color(0xFF1E3A8A));
    final solarGridPaint = overridePaint ?? (Paint()..color = const Color(0xFF93C5FD).withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // Solar panels (Left side, vertical)
    if (overridePaint != null) {
      canvas.drawRect(Rect.fromCenter(center: const Offset(-8, -16), width: 6, height: 22), overridePaint);
      canvas.drawRect(Rect.fromCenter(center: const Offset(-8, 16), width: 6, height: 22), overridePaint);
    } else {
      void drawSolar(Offset pos) {
        canvas.drawRect(Rect.fromCenter(center: pos, width: 6, height: 22), solarPaint);
        // Grid
        canvas.drawLine(Offset(pos.dx, pos.dy - 11), Offset(pos.dx, pos.dy + 11), solarGridPaint);
        for (double i = -9; i <= 9; i += 3) {
          canvas.drawLine(Offset(pos.dx - 3, pos.dy + i), Offset(pos.dx + 3, pos.dy + i), solarGridPaint);
        }
      }
      drawSolar(const Offset(-8, -16));
      drawSolar(const Offset(-8, 16));
    }

    // Radiator panels (Right side, vertical)
    final radiatorRectTop = Rect.fromCenter(center: const Offset(8, -14), width: 4, height: 18);
    final radiatorRectBottom = Rect.fromCenter(center: const Offset(8, 14), width: 4, height: 18);
    if (overridePaint != null) {
      canvas.drawRect(radiatorRectTop, overridePaint);
      canvas.drawRect(radiatorRectBottom, overridePaint);
    } else {
      canvas.drawRect(radiatorRectTop, lightGreyPaint);
      canvas.drawRect(radiatorRectBottom, lightGreyPaint);
      final radGridPaint = Paint()..color = darkGreyPaint.color..style = PaintingStyle.stroke..strokeWidth = 0.5;
      for (double i = -7; i <= 7; i += 3.5) {
        canvas.drawLine(Offset(6, -14 + i), Offset(10, -14 + i), radGridPaint);
        canvas.drawLine(Offset(6, 14 + i), Offset(10, 14 + i), radGridPaint);
      }
    }

    // Central Body (Horizontal)
    // Left Cone
    final conePath = ui.Path();
    conePath.moveTo(-20, -3);
    conePath.lineTo(-12, -6);
    conePath.lineTo(-12, 6);
    conePath.lineTo(-20, 3);
    conePath.close();
    canvas.drawPath(conePath, greyPaint);

    // Left Engine nozzles
    if (overridePaint == null) {
      canvas.drawRect(Rect.fromCenter(center: const Offset(-21, -1.5), width: 2, height: 1.5), darkGreyPaint);
      canvas.drawRect(Rect.fromCenter(center: const Offset(-21, 1.5), width: 2, height: 1.5), darkGreyPaint);
    } else {
      canvas.drawRect(Rect.fromCenter(center: const Offset(-21, 0), width: 2, height: 5), overridePaint);
    }

    // Gold band
    canvas.drawRect(Rect.fromCenter(center: const Offset(-10, 0), width: 4, height: 12), goldPaint);

    // Core Modules (Cylinders)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(-2, 0), width: 12, height: 9), const Radius.circular(1.5)), lightGreyPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(5, 0), width: 2, height: 5), darkGreyPaint); // connector
    
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(12, 0), width: 12, height: 9), const Radius.circular(1.5)), lightGreyPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(19, 0), width: 2, height: 5), darkGreyPaint); // connector
    
    // Right end module
    final endPath = ui.Path();
    endPath.moveTo(20, -4.5);
    endPath.lineTo(25, -2.5);
    endPath.lineTo(25, 2.5);
    endPath.lineTo(20, 4.5);
    endPath.close();
    canvas.drawPath(endPath, greyPaint);
    
    canvas.drawRect(Rect.fromCenter(center: const Offset(26, 0), width: 2, height: 7), darkGreyPaint);
    
    // Right final nozzle
    final nozzlePath = ui.Path();
    nozzlePath.moveTo(27, -1.5);
    nozzlePath.lineTo(31, -4);
    nozzlePath.lineTo(31, 4);
    nozzlePath.lineTo(27, 1.5);
    nozzlePath.close();
    canvas.drawPath(nozzlePath, darkGreyPaint);
  }

  @override
  bool shouldRepaint(covariant _ISSPainter oldDelegate) => false;
}
