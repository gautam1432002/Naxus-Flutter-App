import 'dart:async';
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

class AirPulseScreen extends StatefulWidget {
  const AirPulseScreen({super.key});

  @override
  State<AirPulseScreen> createState() => _AirPulseScreenState();
}

class _AirPulseScreenState extends State<AirPulseScreen> with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final AirQualityService _airQualityService = AirQualityService();
  final LocationStorageService _locationStorageService = LocationStorageService();
  final GeocodingService _geocodingService = GeocodingService();

  LocationModel? _currentLocation;
  WeatherModel? _weather;
  AirQualityModel? _airQuality;
  List<LocationModel> _savedLocations = [];
  
  bool _isLoading = true;

  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

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

    _initData();
  }
  
  @override
  void dispose() {
    _floatController.dispose();
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
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        _weatherService.fetchWeather(_currentLocation!.latitude, _currentLocation!.longitude),
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

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => _SearchBottomSheet(
        geocodingService: _geocodingService,
        onSelect: (location) async {
          await _locationStorageService.saveLastLocation(location);
          await _locationStorageService.addSavedLocation(location);
          _savedLocations = await _locationStorageService.getSavedLocations();
          
          if (mounted) {
            setState(() {
              _currentLocation = location;
              _isLoading = true;
            });
            _fetchData();
          }
        },
      ),
    );
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
                onTap: _openSearchSheet,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _openSearchSheet,
                  ),
                  Expanded(
                    child: Text(
                      _currentLocation!.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: _openManageCities,
                  ),
                ],
              ),
            ),

            // Main Unified Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    SlideTransition(
                      position: _floatAnimation,
                      child: SizedBox(
                        height: 220,
                        width: 220,
                        child: WeatherIllustration(
                          conditionLabel: _weather!.conditionLabel,
                          isDay: _weather!.isDay,
                          animate: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 32),

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
            ),
          ],
        ),
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
      overlayColor: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
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

class _ManageCitiesScreenState extends State<ManageCitiesScreen> {
  final LocationStorageService _locationStorageService = LocationStorageService();
  final WeatherService _weatherService = WeatherService();
  late List<LocationModel> _locations;
  final Map<String, WeatherModel> _weatherCache = {};

  @override
  void initState() {
    super.initState();
    _locations = List.from(widget.savedLocations);
    _loadWeatherData();
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
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'Weather',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Search Location',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_locations.isEmpty)
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
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 32),
                      ),
                      onDismissed: (_) => _deleteLocation(loc),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () {
                            Navigator.pop(context, loc);
                          },
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(32),
                              border: widget.currentLocation?.name == loc.name 
                                ? Border.all(color: Colors.white.withValues(alpha: 0.2)) 
                                : null,
                            ),
                            child: Row(
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
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  final GeocodingService geocodingService;
  final Function(LocationModel) onSelect;
  
  const _SearchBottomSheet({required this.geocodingService, required this.onSelect});
  
  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationModel> _searchResults = [];
  bool _isSearching = false;

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await widget.geocodingService.searchCities(query);
      setState(() => _searchResults = results);
    } catch (_) {}
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      blurSigma: 16.0,
      overlayColor: Colors.black.withValues(alpha: 0.85),
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.4),
                  fontSize: 16,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              const CircularProgressIndicator(color: Colors.white)
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.white.withValues(alpha: 0.05),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final loc = _searchResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      title: Text(
                        loc.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          loc.country,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white24,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(loc);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}