import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import '../models/iss_model.dart';
import '../services/iss_service.dart';

import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/tactile_glass_button.dart';
import '../widgets/nexus_universal_header.dart';
import '../services/app_data_store.dart';
import '../widgets/glass_container.dart';

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

  Widget _buildBentoGridCell(String label, IconData icon, double value, String Function(double) formatter, Color accentColor) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(24),
      blurSigma: 16.0,
      overlayColor: Colors.white.withValues(alpha: 0.03),
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: accentColor.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildTelemetryGraphic(label, accentColor),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGraphic(String label, Color accentColor) {
    if (label == 'LATITUDE') {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
          color: accentColor.withValues(alpha: 0.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 44, height: 1.5, color: accentColor.withValues(alpha: 0.5)),
            Container(
              width: 36,
              height: 2.5,
              decoration: BoxDecoration(
                color: accentColor,
                boxShadow: [BoxShadow(color: accentColor, blurRadius: 4)],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: -15, end: 15, duration: 1.5.seconds, curve: Curves.easeInOut),
          ],
        ),
      );
    } else if (label == 'LONGITUDE') {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
          color: accentColor.withValues(alpha: 0.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 1.5, height: 44, color: accentColor.withValues(alpha: 0.5)),
            Container(
              width: 2.5,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor,
                boxShadow: [BoxShadow(color: accentColor, blurRadius: 4)],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveX(begin: -15, end: 15, duration: 1.5.seconds, curve: Curves.easeInOut),
          ],
        ),
      );
    } else if (label == 'ALTITUDE') {
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 4, 
              height: 44, 
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              )
            ),
            Icon(Icons.keyboard_arrow_up, color: accentColor, size: 24)
             .animate(onPlay: (c) => c.repeat())
             .moveY(begin: 18, end: -18, duration: 2.seconds)
             .fade(begin: 0.2, end: 1.0, duration: 500.ms)
             .then(delay: 500.ms)
             .fade(begin: 1.0, end: 0.0, duration: 500.ms),
          ],
        ),
      );
    } else { // VELOCITY
      return SizedBox(
        width: 44,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                height: 2.5,
                width: 20.0 + (i * 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 4)],
                  borderRadius: BorderRadius.circular(2),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .moveX(begin: -15, end: 15, duration: (500 + i * 150).ms, curve: Curves.easeInOut)
               .fade(begin: 0, end: 1, duration: 250.ms)
               .then(delay: 150.ms)
               .fade(begin: 1, end: 0, duration: 250.ms),
          ],
        ),
      );
    }
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
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
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
                            child: Hero(
                                tag: 'orbit_map',
                                child: GlassContainer(
                                  borderRadius: BorderRadius.circular(36),
                                  blurSigma: 8.0,
                                  overlayColor: Colors.white.withValues(alpha: 0.05),
                                  borderColor: (_isReconnecting ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4)).withValues(alpha: 0.3),
                                  child: _isLoading 
                                          ? const SkeletonLoader(width: double.infinity, height: double.infinity)
                                          : _error != null && _issPosition == null
                                              ? ErrorState(
                                                  accentColor: const Color(0xFF06B6D4),
                                                  message: _error!,
                                                  onRetry: _initFetch,
                                                )
                                              : ClipRRect(
                                                  borderRadius: BorderRadius.circular(36),
                                                  child: _buildMap(),
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
                          sliver: SliverGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            children: [
                              _buildBentoGridCell('LATITUDE', Icons.explore, _issPosition!.latitude, _formatLat, const Color(0xFF3B82F6)),
                              _buildBentoGridCell('LONGITUDE', Icons.public, _issPosition!.longitude, _formatLng, const Color(0xFF8B5CF6)),
                              _buildBentoGridCell('ALTITUDE', Icons.height, _issPosition!.altitude, (val) => '${val.toStringAsFixed(1)} km', const Color(0xFFF59E0B)),
                              _buildBentoGridCell('VELOCITY', Icons.speed, _issPosition!.velocity, (val) => '${val.toStringAsFixed(0)} km/h', const Color(0xFF10B981)),
                            ],
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

class SpaceEnvironmentBackground extends StatelessWidget {
  const SpaceEnvironmentBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base color just in case image is missing
        Container(color: const Color(0xFF060B19)),
        
        // Wallpaper Image
        Image.asset(
          'assets/images/orbit_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Graceful fallback if user hasn't put the image in yet
            return const Center(
              child: Text(
                'Please save image as\nassets/images/orbit_bg.jpg',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            );
          },
        ),
        
        // Dim Effect Overlay
        Container(
          color: Colors.black.withValues(alpha: 0.5), // Adjust this alpha for more/less dimming
        ),
      ],
    );
  }
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
    _drawISSStationShapes(canvas, shadowPaint);
    canvas.restore();

    // Now draw the actual colored station
    _drawISSStationShapes(canvas, null);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ISSPainter oldDelegate) => false;
}

void _drawISSStationShapes(Canvas canvas, Paint? overridePaint) {
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
