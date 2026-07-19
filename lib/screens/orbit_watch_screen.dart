import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/iss_model.dart';
import '../services/iss_service.dart';
import '../theme/app_theme.dart';

class OrbitWatchScreen extends StatefulWidget {
  const OrbitWatchScreen({super.key});

  @override
  State<OrbitWatchScreen> createState() => _OrbitWatchScreenState();
}

class _OrbitWatchScreenState extends State<OrbitWatchScreen> with TickerProviderStateMixin {
  final IssService _issService = IssService();
  final MapController _mapController = MapController();
  
  IssModel? _issPosition;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    try {
      final pos = await _issService.fetchIssPosition();
      if (mounted) {
        setState(() {
          _issPosition = pos;
          _isLoading = false;
        });
        
        // Start periodic polling after successful first fetch
        _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollPosition());
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

    final controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatLat(double lat) => '${lat.abs().toStringAsFixed(2)}° ${lat >= 0 ? 'N' : 'S'}';
  String _formatLng(double lng) => '${lng.abs().toStringAsFixed(2)}° ${lng >= 0 ? 'E' : 'W'}';

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFBBF24); // Amber
    const Color nearBlack = Color(0xFF0A0A12);

    return Container(
      decoration: AppTheme.spaceBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Map or Loading/Error State
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: accentColor),
              )
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _initFetch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: nearBlack,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_issPosition != null)
              FlutterMap(
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
                      Marker(
                        point: LatLng(_issPosition!.latitude, _issPosition!.longitude),
                        width: 60,
                        height: 60,
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
                                    color: accentColor.withOpacity(0.3 * (1.6 - _pulseAnimation.value)),
                                  ),
                                ),
                                // Inner icon
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: nearBlack,
                                    border: Border.all(color: accentColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.satellite_alt,
                                    color: accentColor,
                                    size: 14,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors, © CARTO',
                      ),
                    ],
                  ),
                ],
              ),

            // Back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                child: Hero(
                  tag: 'orbit_watch_hero',
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Info Card
            if (_issPosition != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0C18).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.satellite_alt, color: accentColor, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'ISS Tracker',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Live badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: accentColor.withOpacity(0.5)),
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
                                                color: accentColor.withOpacity(_pulseAnimation.value),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: accentColor.withOpacity(_pulseAnimation.value * 0.5),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Live',
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _InfoStat(label: 'LATITUDE', value: _formatLat(_issPosition!.latitude)),
                                  _InfoStat(label: 'LONGITUDE', value: _formatLng(_issPosition!.longitude)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _InfoStat(label: 'ALTITUDE', value: '${_issPosition!.altitude.toStringAsFixed(1)} km'),
                                  _InfoStat(label: 'VELOCITY', value: '${_issPosition!.velocity.toStringAsFixed(0)} km/h'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
