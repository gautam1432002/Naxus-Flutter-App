import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/air_quality_model.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';

import '../services/air_quality_service.dart';
import '../services/weather_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_storage_service.dart';
import '../services/connectivity_service.dart';


import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/frosted_back_button.dart';
import '../services/app_data_store.dart';

class AirPulseScreen extends StatefulWidget {
  const AirPulseScreen({super.key});

  @override
  State<AirPulseScreen> createState() => _AirPulseScreenState();
}

class _AirPulseScreenState extends State<AirPulseScreen> {
  final AirQualityService _airQualityService = AirQualityService();
  final WeatherService _weatherService = WeatherService();
  final LocationStorageService _locationStorageService = LocationStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();

  LocationModel? _currentLocation;
  
  List<LocationModel> _savedLocations = [];

  AirQualityModel? _airQuality;
  WeatherModel? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final lastLoc = await _locationStorageService.getLastLocation();
      await _loadSavedLocations();
      
      if (lastLoc != null) {
        _currentLocation = lastLoc;
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
          _error = 'Storage Error: $e\n\n(Since we just added the shared_preferences plugin, you must fully stop and restart the app for it to work!)';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedLocations() async {
    final locations = await _locationStorageService.getSavedLocations();
    if (mounted) {
      setState(() {
        _savedLocations = locations;
      });
    }
  }

  Future<void> _fetchData() async {
    if (_currentLocation == null) return;
    
    final store = AppDataStore();
    if (store.airQuality != null && store.weather != null) {
      if (mounted) {
        setState(() {
          _weather = store.weather;
          _airQuality = store.airQuality;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
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
      final results = await Future.wait([
        _weatherService.fetchWeather(_currentLocation!.latitude, _currentLocation!.longitude),
        _airQualityService.fetchAirQuality(_currentLocation!.latitude, _currentLocation!.longitude),
      ]);

      if (mounted) {
        setState(() {
          _weather = results[0] as WeatherModel;
          _airQuality = results[1] as AirQualityModel;
          _isLoading = false;
        });
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

  Future<void> _saveCurrentLocation() async {
    if (_currentLocation == null) return;
    await _locationStorageService.addSavedLocation(_currentLocation!);
    await _loadSavedLocations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_currentLocation!.name} saved!'),
          backgroundColor: const Color(0xFFEC4899),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SearchBottomSheet(
        onSelect: (location) async {
          await _locationStorageService.saveLastLocation(location);
          if (mounted) {
            setState(() {
              _currentLocation = location;
            });
            _fetchData();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
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

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFF7F77DD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 120,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Discover Atmosphere',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Search for a city to view live\nweather and air quality data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _openSearchSheet,
            icon: const Icon(Icons.search),
            label: const Text('Search City'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFFEC4899),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFEC4899)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
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

  Widget _buildAqiStatCard(String title, double value, String unit, IconData icon) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                        color: Colors.white.withValues(alpha: 0.7),
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
                          color: Colors.white.withValues(alpha: 0.5),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: Material(
              color: Color(0xFF0A0A12),
              child: SizedBox.expand(),
            ),
          ),
          Column(
              children: [
                // Header
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        const FrostedBackButton(heroTag: 'air_pulse_hero'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentLocation?.name ?? 'Air Pulse',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _currentLocation?.country ?? 'Global Weather & AQI',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _openSearchSheet,
                        ),
                        if (_currentLocation != null)
                          IconButton(
                            icon: const Icon(Icons.star_border, color: Colors.white),
                            onPressed: _saveCurrentLocation,
                          ),
                      ],
                    ),
                  ),
                ),

                // Saved Locations Chips
                if (_savedLocations.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _savedLocations.length,
                      itemBuilder: (context, index) {
                        final loc = _savedLocations[index];
                        final isSelected = _currentLocation != null && loc.name == _currentLocation!.name && loc.country == _currentLocation!.country;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                          child: GestureDetector(
                            onTap: () async {
                              await _locationStorageService.saveLastLocation(loc);
                              if (mounted) {
                                setState(() {
                                  _currentLocation = loc;
                                });
                                _fetchData();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFF0F172A) 
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? accentColor 
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                loc.name, 
                                style: TextStyle(
                                  color: isSelected ? accentColor : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Main Content Area
                Expanded(
                  child: _isLoading
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Column(
                            children: [
                              const SkeletonLoader(width: double.infinity, height: 140, borderRadius: 24),
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 2.2,
                                children: List.generate(4, (_) => const SkeletonLoader(width: double.infinity, height: 60, borderRadius: 16)),
                              ),
                              const SizedBox(height: 32),
                              const SkeletonLoader(width: 240, height: 240, shape: BoxShape.circle),
                              const SizedBox(height: 32),
                              Row(
                                children: const [
                                  Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 20)),
                                  SizedBox(width: 16),
                                  Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 20)),
                                ],
                              ),
                            ],
                          ),
                        )
                      : _error != null
                          ? ErrorState(
                              accentColor: accentColor,
                              message: _error!,
                              onRetry: _fetchData,
                            )
                          : _currentLocation == null
                              ? _buildEmptyState()
                              : _weather != null && _airQuality != null
                              ? SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                  child: Column(
                                    children: [
                                      // Weather Summary Card
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(24),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${_weather!.temperature.toStringAsFixed(1)}°',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 56,
                                                        fontWeight: FontWeight.bold,
                                                        height: 1.1,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Feels like ${_weather!.feelsLike.toStringAsFixed(1)}°',
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.6),
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Icon(_weather!.conditionIcon, color: accentColor, size: 48),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      _weather!.conditionLabel,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Weather Stats Grid
                                      GridView.count(
                                        crossAxisCount: 2,
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        childAspectRatio: 2.2,
                                        children: [
                                          _buildSmallStatCard('Humidity', '${_weather!.humidity.toStringAsFixed(0)}%', Icons.water_drop_outlined, accentColor),
                                          _buildSmallStatCard('Wind', '${_weather!.windSpeed.toStringAsFixed(1)} km/h', Icons.air, accentColor),
                                          _buildSmallStatCard('UV Index', _weather!.uvIndexMax.toStringAsFixed(1), Icons.wb_sunny_outlined, accentColor),
                                          _buildSmallStatCard('Sun', '${_formatTime(_weather!.sunrise)} / ${_formatTime(_weather!.sunset)}', Icons.wb_twilight, accentColor),
                                        ],
                                      ),
                                      const SizedBox(height: 32),

                                      // AQI Gauge
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0.0, end: _airQuality!.europeanAqi),
                                        duration: const Duration(milliseconds: 1200),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, aqiVal, child) {
                                          final normalizedValue = math.min(aqiVal / 100.0, 1.0);
                                          final activeColor = _getAqiColor(aqiVal);

                                          return SizedBox(
                                            width: 240,
                                            height: 240,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                CustomPaint(
                                                  size: const Size(240, 240),
                                                  painter: AqiGaugePainter(
                                                    value: normalizedValue,
                                                    activeColor: activeColor,
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      aqiVal.toInt().toString(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 56,
                                                        fontWeight: FontWeight.w800,
                                                        shadows: [
                                                          Shadow(
                                                            color: activeColor.withValues(alpha: 0.5),
                                                            blurRadius: 20,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      _getAqiLabel(aqiVal),
                                                      style: TextStyle(
                                                        color: activeColor,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'AQI',
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.4),
                                                        fontSize: 12,
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

                                      // AQI Cards
                                      Row(
                                        children: [
                                          _buildAqiStatCard('PM2.5', _airQuality!.pm2_5, 'µg/m³', Icons.masks_outlined),
                                          const SizedBox(width: 16),
                                          _buildAqiStatCard('PM10', _airQuality!.pm10, 'µg/m³', Icons.blur_on),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  final Function(LocationModel) onSelect;
  const _SearchBottomSheet({required this.onSelect});

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final GeocodingService _geocodingService = GeocodingService();
  Timer? _debounce;
  List<LocationModel> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
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
        if (mounted) setState(() => _searchResults = results);
      } catch (e) {
        // ignore
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF13131E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search city...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFEC4899)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFFEC4899)),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final loc = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city, color: Colors.white54),
                    title: Text(loc.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(loc.country, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
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
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);

    // Foreground track
    final activeSweep = sweepAngle * value;
    
    if (value > 0) {
      // Glow
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.35)
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
