import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/air_quality_model.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/data_result.dart';

import '../services/air_quality_service.dart';
import '../services/weather_service.dart';
import '../services/location_storage_service.dart';
import '../services/geocoding_service.dart';

import '../widgets/glass_container.dart';
import '../widgets/weather_illustration.dart';
import '../widgets/static_discover_cloud.dart';
import '../widgets/nexus_universal_header.dart';
import '../widgets/tactile_glass_button.dart';

class HeaderGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const HeaderGlassButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(12),
        blurSigma: 12.0,
        overlayColor: Colors.white.withValues(alpha: 0.08),
        borderColor: Colors.white.withValues(alpha: 0.15),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class AirPulseScreen extends StatefulWidget {
  const AirPulseScreen({super.key});

  @override
  State<AirPulseScreen> createState() => _AirPulseScreenState();
}

class _AirPulseScreenState extends State<AirPulseScreen> with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final AirQualityService _airQualityService = AirQualityService();
  final LocationStorageService _locationStorageService = LocationStorageService();

  LocationModel? _currentLocation;
  WeatherModel? _weather;
  AirQualityModel? _airQuality;
  List<LocationModel> _savedLocations = [];
  
  bool _isLoading = true;

  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _starController;
  List<ManageCitiesStarParticle>? _particles;

  @override
  void initState() {
    super.initState();
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: const Offset(0, 0.05),
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _scrollController.addListener(() {
      // Keep alive for AnimatedBuilder
    });

    _initData();
  }
  
  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _starController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      final lastLoc = await _locationStorageService.getLastLocation();
      _savedLocations = await _locationStorageService.getSavedLocations();
      
      if (_savedLocations.isNotEmpty) {
        _currentLocation = lastLoc ?? _savedLocations.first;
        await _fetchData();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchData() async {
    if (_currentLocation == null) return;
    
    final cached = WeatherService.getCachedWeather(_currentLocation!.name);
    
    if (mounted) {
      setState(() {
        if (cached != null) {
          _weather = cached;
          _isLoading = false;
        } else {
          _isLoading = true;
        }
      });
    }

    try {
      final results = await Future.wait([
        _weatherService.fetchWeather(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          locationName: _currentLocation!.name,
        ),
        _airQualityService.fetchAirQuality(_currentLocation!.latitude, _currentLocation!.longitude),
      ]);

      if (mounted) {
        setState(() {
          final weatherResult = results[0] as DataResult<WeatherModel>;
          final aqiResult = results[1] as DataResult<AirQualityModel>;
          _weather = weatherResult.data;
          _airQuality = aqiResult.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveCurrentLocation() async {
    if (_currentLocation == null) return;
    
    bool isSaved = _savedLocations.any((loc) => loc.name == _currentLocation!.name);
    
    if (!isSaved) {
      await _locationStorageService.saveLastLocation(_currentLocation!);
      await _locationStorageService.addSavedLocation(_currentLocation!);
      _savedLocations = await _locationStorageService.getSavedLocations();
      if (mounted) setState(() {});
    }
    
    _pulseController.forward(from: 0.0);
  }

  void _openManageCities() async {
    final LocationModel? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageCitiesScreen(
          savedLocations: _savedLocations,
          currentLocation: _currentLocation,
        ),
      ),
    );

    // Refresh state after returning
    _savedLocations = await _locationStorageService.getSavedLocations();
    
    if (selectedLocation != null) {
      // User tapped a city to switch to it
      await _locationStorageService.saveLastLocation(selectedLocation);
      setState(() {
        _currentLocation = selectedLocation;
      });
      _fetchData();
    } else {
      // User just backed out, but they might have deleted the current city or all cities
      if (_savedLocations.isEmpty) {
        setState(() {
          _currentLocation = null;
        });
      } else if (!_savedLocations.any((loc) => loc.name == _currentLocation?.name)) {
        // If current location was deleted, fall back to first available
        setState(() {
          _currentLocation = _savedLocations.first;
        });
        await _locationStorageService.saveLastLocation(_savedLocations.first);
        _fetchData();
      } else {
        setState(() {}); // Just rebuild to reflect any deletions
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_savedLocations.isEmpty) {
      return _buildDiscoverScreen();
    }

    return _buildActiveWeatherScreen();
  }

  Widget _buildDiscoverScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Discover The\nWeather In Your City',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const Spacer(flex: 1),
            SlideTransition(
              position: _floatAnimation,
              child: const SizedBox(
                height: 250,
                width: 250,
                child: StaticDiscoverCloud(),
              ),
            ),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Get to know your weather maps and radar precipitation forcast',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: GestureDetector(
                onTap: _openManageCities,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Text(
                      'GET STARTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWeatherScreen() {
    if (_weather == null || _currentLocation == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_particles == null) {
      final size = MediaQuery.of(context).size;
      final random = math.Random(42);
      _particles = List.generate(45, (index) {
        return ManageCitiesStarParticle(
          x: random.nextDouble() * size.width,
          y: random.nextDouble() * size.height,
          radius: random.nextDouble() * 1.5 + 0.5,
          opacity: random.nextDouble() * 0.5 + 0.1,
          speed: random.nextDouble() * 0.5 + 0.1,
        );
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient (Matches ManageCitiesScreen)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.8),
                radius: 1.5,
                colors: [
                  Color(0xFF1E293B),
                  Colors.black,
                ],
              ),
            ),
          ),
          
          // Starfield Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _starController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ManageCitiesStarfieldPainter(_particles!, _starController.value),
                );
              },
            ),
          ),

          // Main Unified Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 140), // Space for Header + Big Title
                SlideTransition(
                  position: _floatAnimation,
                  child: SizedBox(
                    height: 180,
                    width: 180,
                    child: WeatherIllustration(
                      conditionLabel: _weather!.conditionLabel,
                      isDay: _weather!.isDay,
                      animate: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_weather!.temperature.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.w300,
                    height: 1.0,
                    letterSpacing: -2.0,
                  ),
                ),
                Text(
                  _weather!.conditionLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 24),

                // AQI / Stats Panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(24),
                    blurSigma: 16.0,
                    overlayColor: Colors.white.withValues(alpha: 0.05),
                    borderColor: Colors.white.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('AQI', _airQuality?.europeanAqi.round().toString() ?? '--', _getAqiColor(_airQuality?.europeanAqi ?? 0)),
                          _buildStatItem('HUMIDITY', '${_weather!.humidity.round()}%', Colors.blueAccent),
                          _buildStatItem('WIND', '${_weather!.windSpeed.round()} km/h', Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Hourly Forecast Section
                _buildHourlyForecastSection(),
                const SizedBox(height: 40),

                // Weekly Forecast Section
                _buildWeeklyForecastSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Universal Header (matches Echoes screen)
          NexusUniversalHeader(
            onBack: () => Navigator.pop(context),
            actions: [
              TactileGlassButton(
                icon: Icons.search,
                onTap: _openManageCities,
              ),
            ],
          ),

          // Dynamic Title Overlay
          AnimatedBuilder(
            animation: Listenable.merge([_scrollController, _pulseController]),
            builder: (context, child) {
              double offset = 0;
              if (_scrollController.hasClients) {
                offset = _scrollController.offset;
              }
              
              // 0 -> 100 scroll offset controls the transition
              double progress = (offset / 100).clamp(0.0, 1.0);
              
              double topPadding = MediaQuery.of(context).padding.top;
              
              // Start position: center of the screen, just above illustration
              double startTop = topPadding + 64; 
              // End position: inside the NexusUniversalHeader
              double endTop = topPadding + 14; 
              
              double currentTop = startTop - (startTop - endTop) * progress;
              
              // Font size interpolation
              double currentSize = 40 - (40 - 16) * progress;
              // Letter spacing interpolation
              double currentSpacing = 0.5 - (0.5 - 0.0) * progress;
              
              // Capsule styling interpolation
              double capsuleOpacity = progress;
              double paddingH = 0 + (16 * progress);
              double paddingV = 0 + (6 * progress);

              return Positioned(
                top: currentTop,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _saveCurrentLocation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10.0 * capsuleOpacity + 0.001,
                          sigmaY: 10.0 * capsuleOpacity + 0.001,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1 * capsuleOpacity),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2 * capsuleOpacity),
                              width: 1.0 * capsuleOpacity,
                            ),
                          ),
                          child: Text(
                            _currentLocation!.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: currentSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: currentSpacing,
                              shadows: [
                                Shadow(
                                  color: Colors.greenAccent.withValues(alpha: _pulseAnimation.value),
                                  blurRadius: 16.0,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color dotColor) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 8.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getAqiColor(double aqi) {
    if (aqi == 0) return Colors.grey;
    if (aqi <= 33) return const Color(0xFF10B981); 
    if (aqi <= 66) return const Color(0xFFF59E0B); 
    return const Color(0xFFEF4444); 
  }

  Widget _buildHourlyForecastSection() {
    if (_weather == null || _weather!.hourlyForecast.isEmpty) return const SizedBox.shrink();

    // Filter upcoming hours
    final now = DateTime.now();
    final upcomingHours = _weather!.hourlyForecast.where((h) => 
      h.time.isAfter(now.subtract(const Duration(minutes: 59)))
    ).take(24).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              const Icon(Icons.access_time_filled, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'HOURLY FORECAST',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: upcomingHours.length,
            itemBuilder: (context, index) {
              final hourly = upcomingHours[index];
              final isCurrentHour = index == 0;
              final hr = hourly.time.hour;
              final suffix = hr >= 12 ? 'PM' : 'AM';
              final displayHr = hr % 12 == 0 ? 12 : hr % 12;
              final hourLabel = '$displayHr $suffix';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InteractiveWeatherCard(
                  width: 90,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        hourLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: isCurrentHour ? 1.0 : 0.6),
                          fontSize: 16,
                          fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: InteractiveWeatherIllustration(
                          conditionLabel: hourly.conditionLabel,
                          isDay: hourly.isDay,
                        ),
                      ),
                      Text(
                        '${hourly.temperature.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyForecastSection() {
    // Generate dummy weekly data
    final baseTemp = _weather!.temperature.round();
    final days = ['Today', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '7-DAY FORECAST',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (index) {
            final high = baseTemp + (index % 4);
            final low = baseTemp - 5 - (index % 3);
            final condition = index % 2 == 0 ? 'Clear' : (index == 3 ? 'Storm' : 'Cloudy');            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InteractiveWeatherCard(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: SizedBox(
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Day Text
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          days[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: index == 0 ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      // Temperature Center
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$low°',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 60,
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.blue, Colors.orange],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$high°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Positioned Icon
                      Positioned(
                        top: -4,
                        right: 0,
                        child: SizedBox(
                          height: 40,
                          width: 40,
                          child: InteractiveWeatherIllustration(
                            conditionLabel: condition,
                            isDay: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class InteractiveWeatherCard extends StatelessWidget {
  final Widget child;
  final double width;
  final EdgeInsetsGeometry padding;

  const InteractiveWeatherCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(24),
      blurSigma: 12.0,
      overlayColor: Colors.white.withValues(alpha: 0.05),
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class InteractiveWeatherIllustration extends StatefulWidget {
  final String conditionLabel;
  final bool isDay;

  const InteractiveWeatherIllustration({
    super.key,
    required this.conditionLabel,
    this.isDay = true,
  });

  @override
  State<InteractiveWeatherIllustration> createState() => _InteractiveWeatherIllustrationState();
}

class _InteractiveWeatherIllustrationState extends State<InteractiveWeatherIllustration> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setHovered(bool hovered) {
    setState(() {
      _isHovered = hovered;
      if (hovered) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.animateTo(0.0, duration: const Duration(milliseconds: 300));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final condition = widget.conditionLabel.toLowerCase();
    IconData iconData = Icons.wb_sunny;
    List<Color> gradientColors = [Colors.yellowAccent, Colors.orangeAccent];
    Color glowColor = Colors.orangeAccent;

    if (condition.contains('cloud') || condition.contains('overcast') || condition.contains('fog') || condition.contains('partly')) {
      iconData = Icons.cloud;
      gradientColors = [Colors.white, Colors.lightBlue.shade100];
      glowColor = Colors.lightBlue.shade200;
    } else if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('shower')) {
      iconData = Icons.water_drop;
      gradientColors = [Colors.lightBlueAccent, Colors.blue];
      glowColor = Colors.blueAccent;
    } else if (condition.contains('storm') || condition.contains('thunder')) {
      iconData = Icons.flash_on;
      gradientColors = [Colors.yellow, Colors.deepOrange];
      glowColor = Colors.amber;
    } else if (condition.contains('snow')) {
      iconData = Icons.ac_unit;
      gradientColors = [Colors.white, Colors.cyan.shade100];
      glowColor = Colors.cyan;
    } else if (!widget.isDay && !condition.contains('sun') && !condition.contains('clear')) {
      iconData = Icons.nightlight_round;
      gradientColors = [Colors.indigo.shade200, Colors.deepPurpleAccent];
      glowColor = Colors.deepPurple;
    } else if (!widget.isDay) {
      iconData = Icons.nightlight_round;
      gradientColors = [Colors.indigo.shade200, Colors.deepPurpleAccent];
      glowColor = Colors.deepPurple;
    }

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setHovered(true),
        onTapUp: (_) => _setHovered(false),
        onTapCancel: () => _setHovered(false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxWidth * 0.8;
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 3D Drop Shadow
                        Transform.translate(
                          offset: const Offset(2, 3),
                          child: Icon(
                            iconData,
                            size: iconSize,
                            color: Colors.black.withValues(alpha: 0.6),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(1, 2),
                                blurRadius: 4.0,
                              ),
                            ],
                          ),
                        ),
                        // Top Highlight for Bevel
                        Transform.translate(
                          offset: const Offset(-1, -1),
                          child: Icon(
                            iconData,
                            size: iconSize,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        // Main Gradient Icon
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ).createShader(bounds);
                          },
                          child: Icon(
                            iconData,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ManageCitiesScreen extends StatefulWidget {
  final List<LocationModel> savedLocations;
  final LocationModel? currentLocation;

  const ManageCitiesScreen({
    super.key,
    required this.savedLocations,
    required this.currentLocation,
  });

  @override
  State<ManageCitiesScreen> createState() => _ManageCitiesScreenState();
}

class ManageCitiesStarParticle {
  double x;
  double y;
  double radius;
  double opacity;
  double speed;

  ManageCitiesStarParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.speed,
  });
}

class ManageCitiesStarfieldPainter extends CustomPainter {
  final List<ManageCitiesStarParticle> particles;
  final double animationValue;
  final Paint _paint = Paint();

  ManageCitiesStarfieldPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      double currentY = (particle.y + (particle.speed * animationValue * size.height)) % size.height;
      double currentOpacity = particle.opacity * (0.5 + 0.5 * math.sin(animationValue * math.pi * 2 + particle.x));
      _paint.color = Colors.white.withValues(alpha: currentOpacity);
      canvas.drawCircle(Offset(particle.x, currentY), particle.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ManageCitiesScreenState extends State<ManageCitiesScreen> with TickerProviderStateMixin {
  final LocationStorageService _locationStorageService = LocationStorageService();
  final WeatherService _weatherService = WeatherService();
  final GeocodingService _geocodingService = GeocodingService();
  late List<LocationModel> _locations;
  final Map<String, WeatherModel> _weatherCache = {};

  final TextEditingController _searchController = TextEditingController();
  List<LocationModel> _searchResults = [];
  bool _isSearching = false;

  void _onSearch(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }
    
    if (mounted) setState(() => _isSearching = true);
    
    try {
      final results = await _geocodingService.searchCities(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onSelectSearchResult(LocationModel location) async {
    await _locationStorageService.saveLastLocation(location);
    await _locationStorageService.addSavedLocation(location);
    
    if (mounted) {
      setState(() {
        if (!_locations.any((loc) => loc.name == location.name)) {
          _locations.insert(0, location);
        }
        _searchController.clear();
        _searchResults = [];
        _isSearching = false;
      });
      _loadWeatherDataFor(location);
    }
  }

  Future<void> _loadWeatherDataFor(LocationModel location) async {
    try {
      final result = await _weatherService.fetchWeather(location.latitude, location.longitude);
      if (mounted) {
        setState(() {
          _weatherCache[location.name] = result.data;
        });
      }
    } catch (_) {}
  }

  late AnimationController _starController;
  late AnimationController _shimmerController;
  List<ManageCitiesStarParticle>? _particles;

  @override
  void initState() {
    super.initState();
    _locations = List.from(widget.savedLocations);
    _loadWeatherData();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _starController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _initParticles(Size size) {
    if (_particles != null) return;
    final random = math.Random(42);
    _particles = List.generate(45, (index) {
      return ManageCitiesStarParticle(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        radius: random.nextDouble() * 1.5 + 0.5,
        opacity: random.nextDouble() * 0.5 + 0.2,
        speed: random.nextDouble() * 0.2 + 0.05,
      );
    });
  }

  Future<void> _loadWeatherData() async {
    for (var loc in _locations) {
      if (!mounted) return;
      try {
        final res = await _weatherService.fetchWeather(loc.latitude, loc.longitude);
        if (mounted) {
          setState(() {
            _weatherCache[loc.name] = res.data;
          });
        }
      } catch (e) {
        // Handle gracefully
      }
    }
  }

  void _deleteLocation(LocationModel loc) async {
    await _locationStorageService.removeSavedLocation(loc);
    setState(() {
      _locations.removeWhere((l) => l.name == loc.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020015), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              _initParticles(Size(constraints.maxWidth, constraints.maxHeight));
              return AnimatedBuilder(
                animation: _starController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ManageCitiesStarfieldPainter(_particles!, _starController.value),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  );
                },
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 56), // Space for NexusUniversalHeader overlay
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    blurSigma: 12.0,
                    overlayColor: Colors.white.withValues(alpha: 0.05),
                    borderColor: Colors.white.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearch,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Search Location',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                              child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.5), size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isSearching)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final loc = _searchResults[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _onSelectSearchResult(loc),
                            child: GlassContainer(
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white, size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        if (loc.country.isNotEmpty)
                                          Text(
                                            loc.country,
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else if (_locations.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No cities saved.', style: TextStyle(color: Colors.white)),
                    ),
                  )
                else
                  Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    
                    return Dismissible(
                      key: Key(loc.name),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24.0),
                        margin: const EdgeInsets.only(bottom: 24.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 36),
                      ),
                      onDismissed: (_) => _deleteLocation(loc),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () {
                            Navigator.pop(context, loc);
                          },
                          child: GlassContainer(
                            height: 140,
                            borderRadius: BorderRadius.circular(32),
                            blurSigma: 12.0,
                            overlayColor: Colors.white.withValues(alpha: 0.05),
                            borderColor: widget.currentLocation?.name == loc.name 
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _shimmerController,
                                      builder: (context, child) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.white.withValues(alpha: 0.08),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                              begin: Alignment(-2.0 + (_shimmerController.value * 4.0), -0.5),
                                              end: Alignment(0.0 + (_shimmerController.value * 4.0), 0.5),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _weatherCache.containsKey(loc.name) ? '${_weatherCache[loc.name]!.temperature.round()}°' : '--°',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.w300,
                                                  height: 1.0,
                                                  letterSpacing: -1.0,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _weatherCache.containsKey(loc.name) ? 'H:${_weatherCache[loc.name]!.dailyMaxTemp.round()}° L:${_weatherCache[loc.name]!.dailyMinTemp.round()}°' : 'H:--° L:--°',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                loc.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: -20,
                                              top: -20,
                                              child: SizedBox(
                                                height: 140,
                                                width: 140,
                                                child: _weatherCache.containsKey(loc.name)
                                                    ? WeatherIllustration(
                                                        conditionLabel: _weatherCache[loc.name]!.conditionLabel,
                                                        isDay: _weatherCache[loc.name]!.isDay,
                                                      )
                                                    : const Center(child: CircularProgressIndicator(color: Colors.white24)),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 24,
                                              right: 24,
                                              child: Text(
                                                _weatherCache.containsKey(loc.name) ? _weatherCache[loc.name]!.conditionLabel : '...',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
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
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      NexusUniversalHeader(
        onBack: () => Navigator.pop(context),
        center: const Text(
          'Manage Cities',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  ),
);
  }
}