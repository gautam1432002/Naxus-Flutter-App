import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/air_quality_model.dart';
import '../services/air_quality_service.dart';
import '../theme/app_theme.dart';

class AirPulseScreen extends StatefulWidget {
  const AirPulseScreen({super.key});

  @override
  State<AirPulseScreen> createState() => _AirPulseScreenState();
}

class _AirPulseScreenState extends State<AirPulseScreen> with SingleTickerProviderStateMixin {
  final AirQualityService _airQualityService = AirQualityService();
  AirQualityModel? _airQuality;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    
    _loadAirQuality();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAirQuality() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aqi = await _airQualityService.fetchAirQuality();
      setState(() {
        _airQuality = aqi;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getAqiColor(double aqi) {
    if (aqi <= 33) return const Color(0xFF34D399); // Green
    if (aqi <= 66) return const Color(0xFFFBBF24); // Amber
    return const Color(0xFFF87171); // Red
  }

  String _getAqiLabel(double aqi) {
    if (aqi <= 33) return 'Good';
    if (aqi <= 66) return 'Moderate';
    return 'Poor';
  }

  Widget _buildStatCard(String title, double value, String unit, IconData icon) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFEC4899);
    const Color nearBlack = Color(0xFF0A0A12);

    return Container(
      decoration: AppTheme.spaceBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // States
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
                      onPressed: _loadAirQuality,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: nearBlack,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_airQuality != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0, left: 72.0, right: 24.0, bottom: 16.0),
                      child: Hero(
                        tag: 'air_pulse_hero',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            'Air Pulse',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        children: [
                          // Gauge
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              final aqi = _airQuality!.europeanAqi;
                              final normalizedValue = math.min(aqi / 100.0, 1.0);
                              final animatedValue = normalizedValue * _animation.value;
                              final activeColor = _getAqiColor(aqi);

                              return SizedBox(
                                width: 280,
                                height: 280,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(280, 280),
                                      painter: AqiGaugePainter(
                                        value: animatedValue,
                                        activeColor: activeColor,
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          (aqi * _animation.value).toInt().toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 64,
                                            fontWeight: FontWeight.w800,
                                            shadows: [
                                              Shadow(
                                                color: activeColor.withOpacity(0.5),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _getAqiLabel(aqi),
                                          style: TextStyle(
                                            color: activeColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'AQI',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.4),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),

                          // Cards
                          Row(
                            children: [
                              _buildStatCard('PM2.5', _airQuality!.pm2_5, 'µg/m³', Icons.masks_outlined),
                              const SizedBox(width: 16),
                              _buildStatCard('PM10', _airQuality!.pm10, 'µg/m³', Icons.blur_on),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Location Context
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, color: Colors.white.withOpacity(0.4), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Indore / Bhopal region',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Safe-area aware back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
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

class AqiGaugePainter extends CustomPainter {
  final double value;
  final Color activeColor;

  AqiGaugePainter({required this.value, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 10;
    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);

    // Foreground track
    final activeSweep = sweepAngle * value;
    
    if (value > 0) {
      // Glow
      final glowPaint = Paint()
        ..color = activeColor.withOpacity(0.35)
        ..strokeWidth = 28
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeSweep, false, glowPaint);

      // Actual foreground
      final fgPaint = Paint()
        ..color = activeColor
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeSweep, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AqiGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.activeColor != activeColor;
  }
}
