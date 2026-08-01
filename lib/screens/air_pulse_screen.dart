import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/air_quality_model.dart';
import '../models/weather_model.dart';
import '../models/location_model.dart';
import '../models/data_result.dart';

import '../services/air_quality_service.dart';
import '../services/weather_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_storage_service.dart';

import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/tactile_glass_button.dart';
import '../widgets/nexus_universal_header.dart';
import '../widgets/weather_illustration.dart';
import '../services/app_data_store.dart';

enum ActiveDashboardCard { weather, aqi }

class AirPulseScreen extends StatefulWidget {
  const AirPulseScreen({super.key});

  @override
  State<AirPulseScreen> createState() => _AirPulseScreenState();
}

class _AirPulseScreenState extends State<AirPulseScreen> {
  final AirQualityService _airQualityService = AirQualityService();
  final WeatherService _weatherService = WeatherService();
  final LocationStorageService _locationStorageService = LocationStorageService();

  LocationModel? _currentLocation;
  List<LocationModel> _savedLocations = [];

  AirQualityModel? _airQuality;
  WeatherModel? _weather;
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;
  ActiveDashboardCard _activeCard = ActiveDashboardCard.aqi;

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
          _isOffline = weatherResult.isOffline || aqiResult.isOffline;
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
  }

  Future<void> _removeLocation(LocationModel loc) async {
    await _locationStorageService.removeSavedLocation(loc);
    await _loadSavedLocations();
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => _SearchBottomSheet(
        onSelect: (location) async {
          await _locationStorageService.saveLastLocation(location);
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

  void _showDeleteContextMenu(LocationModel loc) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Manage ${loc.name}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _removeLocation(loc);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.delete_outline, color: Color(0xFFE11D48)),
                            SizedBox(width: 8),
                            Text(
                              'Remove City',
                              style: TextStyle(
                                color: Color(0xFFE11D48),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getAqiColor(double aqi) {
    if (aqi <= 33) return const Color(0xFF10B981); // Green
    if (aqi <= 66) return const Color(0xFFF59E0B); // Yellow/Orange
    return const Color(0xFFEF4444); // Red
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
              colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
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
              color: Color(0xFF0F172A),
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
              color: Color(0xFF64748B),
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
              backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF0284C7),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCell(String title, String value, IconData icon, Color accentColor, int index) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 400),
      columnCount: 2,
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.45),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            title.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAqiSecondaryCard(String title, double value, String unit, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: const Color(0xFF64748B), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
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
                          color: Color(0xFF0F172A),
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
                            color: const Color(0xFF0F172A).withValues(alpha: 0.5),
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
      ),
    );
  }
  
  Widget _buildWeatherBento() {
    final isActive = _activeCard == ActiveDashboardCard.weather;
    
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          HapticFeedback.selectionClick();
          setState(() => _activeCard = ActiveDashboardCard.weather);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive 
              ? [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.35)]
              : [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.15)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: isActive ? 0.75 : 0.40), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: isActive ? 0.08 : 0.03),
              blurRadius: isActive ? 24 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_weather!.temperature.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Feels like ${_weather!.feelsLike.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _weather!.conditionLabel,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Opacity(
                        opacity: isActive ? 1.0 : 0.6,
                        child: WeatherIllustration(
                          conditionLabel: _weather!.conditionLabel,
                          isDay: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAqiBento() {
    final isActive = _activeCard == ActiveDashboardCard.aqi;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          HapticFeedback.selectionClick();
          setState(() => _activeCard = ActiveDashboardCard.aqi);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive 
              ? [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.35)]
              : [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.15)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: isActive ? 0.75 : 0.40), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: isActive ? 0.08 : 0.03),
              blurRadius: isActive ? 24 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: _airQuality!.europeanAqi),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, aqiVal, child) {
                  final normalizedValue = math.min(aqiVal / 100.0, 1.0);
                  final activeColor = _getAqiColor(aqiVal);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 110,
                        width: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(110, 110),
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
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  _getAqiLabel(aqiVal).toUpperCase(),
                                  style: TextStyle(
                                    color: activeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'AIR QUALITY',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDashboardContent() {
    if (_isLoading) {
      return Padding(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
              const SkeletonLoader(width: double.infinity, height: 220, borderRadius: 28),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.0,
                children: List.generate(4, (_) => const SkeletonLoader(width: double.infinity, height: 80, borderRadius: 24)),
              ),
            ],
        ),
      );
    }
    
    if (_error != null) {
      return ErrorState(
        key: const ValueKey('error'),
        accentColor: const Color(0xFFE11D48),
        message: _error!,
        onRetry: _fetchData,
      );
    }
    
    if (_currentLocation == null) {
      return Padding(
        key: const ValueKey('empty'),
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
        child: _buildEmptyState(),
      );
    }
    
    if (_weather != null && _airQuality != null) {
      return Padding(
        key: const ValueKey('dashboard'),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Title Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _currentLocation!.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF0284C7),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _currentLocation!.country,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Balanced Weather & AQI Row
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildWeatherBento(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildAqiBento(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Weather Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.0, 
                children: [
                  _buildBentoCell('Humidity', '${_weather!.humidity.toStringAsFixed(0)}%', Icons.water_drop_outlined, const Color(0xFF0284C7), 0),
                  _buildBentoCell('Wind', '${_weather!.windSpeed.toStringAsFixed(1)} km/h', Icons.air, const Color(0xFF0284C7), 1),
                  _buildBentoCell('UV Index', _weather!.uvIndexMax.toStringAsFixed(1), Icons.wb_sunny_outlined, const Color(0xFF0284C7), 2),
                  _buildBentoCell('Sun', '${_formatTime(_weather!.sunrise)} / ${_formatTime(_weather!.sunset)}', Icons.wb_twilight, const Color(0xFF0284C7), 3),
                ],
              ),
              const SizedBox(height: 24),

              // AQI Secondary Cards
              Row(
                children: [
                  _buildAqiSecondaryCard('PM2.5', _airQuality!.pm2_5, 'µg/m³', Icons.masks_outlined),
                  const SizedBox(width: 16),
                  _buildAqiSecondaryCard('PM10', _airQuality!.pm10, 'µg/m³', Icons.blur_on),
                ],
              ),
              const SizedBox(height: 120),
            ],
        ),
      );
    }
    
    return const SizedBox.shrink(key: ValueKey('none'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Layer 0: Dynamic Ambient Sky Layer
          Positioned.fill(
            child: AtmosphericBackground(
              weather: _weather,
              airQuality: _airQuality,
              activeCard: _activeCard,
            ),
          ),
          
          // Layer 1: Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Padding for the fixed header
              SliverPadding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 80),
              ),
              
              // Saved Locations Chips (Scrolls with content)
              if (_savedLocations.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _savedLocations.length,
                      itemBuilder: (context, index) {
                        final loc = _savedLocations[index];
                        final isSelected = _currentLocation != null && loc.name == _currentLocation!.name && loc.country == _currentLocation!.country;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await _locationStorageService.saveLastLocation(loc);
                              if (mounted) {
                                setState(() {
                                  _currentLocation = loc;
                                  _isLoading = true;
                                });
                                _fetchData();
                              }
                            },
                            onLongPress: () => _showDeleteContextMenu(loc),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFF0F172A) 
                                    : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.transparent 
                                      : Colors.white.withValues(alpha: 0.6),
                                  width: 1.0,
                                ),
                                boxShadow: isSelected 
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                              ),
                              child: Text(
                                loc.name, 
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
              if (_savedLocations.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Main Dashboard
              SliverToBoxAdapter(
                child: PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation, secondaryAnimation) {
                    return FadeThroughTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: _buildDashboardContent(),
                ),
              ),
            ],
          ),

          // Layer 2: Fixed Hovering Header (Universal)
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
              if (_currentLocation != null)
                TactileGlassButton(
                  icon: Icons.star_border,
                  onTap: _saveCurrentLocation,
                ),
              const SizedBox(width: 4),
              TactileGlassButton(
                icon: Icons.search,
                onTap: _openSearchSheet,
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              children: [
                // Top Pill
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                
                // Search Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                      ),
                      child: TextField(
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search city...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Results List
                if (_isSearching)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final loc = _searchResults[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onSelect(loc);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                                          ),
                                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                loc.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                loc.country,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.6),
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ATMOSPHERIC BACKGROUND (Dynamic Sky & Weather Particles)
// ---------------------------------------------------------

class AtmosphericBackground extends StatefulWidget {
  final WeatherModel? weather;
  final AirQualityModel? airQuality;
  final ActiveDashboardCard? activeCard;

  const AtmosphericBackground({super.key, this.weather, this.airQuality, this.activeCard});

  @override
  State<AtmosphericBackground> createState() => _AtmosphericBackgroundState();
}

class _AtmosphericBackgroundState extends State<AtmosphericBackground> with SingleTickerProviderStateMixin {
  late AnimationController _timeController;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWeather = widget.activeCard == ActiveDashboardCard.weather;
    bool isRaining = false;
    bool isSnowing = false;

    if (isWeather && widget.weather != null) {
      final label = widget.weather!.conditionLabel.toLowerCase();
      if (label.contains('rain') || label.contains('drizzle') || label.contains('thunder')) {
        isRaining = true;
      } else if (label.contains('snow')) {
        isSnowing = true;
      }
    }

    return Stack(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: isWeather ? 1.0 : 0.0, end: isWeather ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
          builder: (context, transition, child) {
            return AnimatedBuilder(
              animation: _timeController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: AtmosphericBackgroundPainter(
                    transition: transition,
                    time: _timeController.value,
                    weather: widget.weather,
                    aqi: widget.airQuality,
                  ),
                );
              },
            );
          },
        ),
        if (isRaining || isSnowing)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: isWeather ? 1.0 : 0.0, end: isWeather ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 1200),
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: WeatherParticleEmitter(
                    isSnowing: isSnowing,
                    isRaining: isRaining,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class AtmosphericBackgroundPainter extends CustomPainter {
  final double transition;
  final double time;
  final WeatherModel? weather;
  final AirQualityModel? aqi;

  AtmosphericBackgroundPainter({
    required this.transition,
    required this.time,
    this.weather,
    this.aqi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base color interpolation
    final baseAqi = const Color(0xFFF1F5F9);
    final isDarkWeather = weather?.conditionLabel.toLowerCase().contains('rain') == true || 
                          weather?.conditionLabel.toLowerCase().contains('snow') == true;
    final baseWeather = isDarkWeather ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9);
    final baseColor = Color.lerp(baseAqi, baseWeather, transition)!;
    canvas.drawColor(baseColor, BlendMode.srcOver);

    // 2. Static Background Elements (Rich, slightly saturated)
    _drawStaticDecorations(canvas, size);

    // 3. Morphing Ambient AQI -> Weather Elements
    Color c1 = const Color(0xFF10B981); // AQI Green
    Color c2 = const Color(0xFF3B82F6); // AQI Blue
    if (aqi != null) {
      final aqiVal = aqi!.europeanAqi;
      if (aqiVal > 66) { c1 = const Color(0xFFEF4444); c2 = const Color(0xFFF97316); }
      else if (aqiVal > 33) { c1 = const Color(0xFFEAB308); c2 = const Color(0xFFF97316); }
    }

    final aqiTopLeft = const Offset(-50, -50);
    final aqiTopLeftRadius = 250.0;
    
    final aqiBottomRight = Offset(size.width - 50, size.height - 150);
    final aqiBottomRightRadius = 300.0;

    String cond = weather?.conditionLabel.toLowerCase() ?? 'clear';
    bool isCloudy = cond.contains('cloud');
    bool isRain = cond.contains('rain') || cond.contains('drizzle') || cond.contains('thunder');
    bool isSnow = cond.contains('snow');
    bool isClear = !isCloudy && !isRain && !isSnow;

    if (isClear) {
      // Morph Top-Left AQI -> Sun in Top-Right
      final sunCenter = Offset.lerp(aqiTopLeft, Offset(size.width - 60, 180), transition)!;
      final sunRadius = ui.lerpDouble(aqiTopLeftRadius, 140.0, transition)!;
      
      final sunGlow = Paint()
        ..shader = ui.Gradient.radial(sunCenter, sunRadius * 1.5, [
          Color.lerp(c1.withValues(alpha: 0.15), const Color(0xFFFDE047).withValues(alpha: 0.4), transition)!,
          Color.lerp(c1.withValues(alpha: 0.0), const Color(0xFFF59E0B).withValues(alpha: 0.0), transition)!,
        ]);
      canvas.drawCircle(sunCenter, sunRadius * 1.5, sunGlow);
      
      if (transition > 0) {
        final sunBody = Paint()
          ..shader = ui.Gradient.linear(
            Offset(sunCenter.dx, sunCenter.dy - sunRadius),
            Offset(sunCenter.dx, sunCenter.dy + sunRadius),
            [
              Color.lerp(c1.withValues(alpha: 0.0), const Color(0xFFFEF08A), transition)!,
              Color.lerp(c1.withValues(alpha: 0.0), const Color(0xFFF59E0B), transition)!,
            ]
          );
        canvas.drawCircle(sunCenter, sunRadius * transition, sunBody);
        
        // Rotating rays
        final rayPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero, Offset(0, sunRadius + 40),
            [
               const Color(0xFFFDE047).withValues(alpha: 0.5 * transition),
               const Color(0xFFF59E0B).withValues(alpha: 0.0),
            ]
          )
          ..strokeWidth = 8 * transition
          ..strokeCap = StrokeCap.round;

        canvas.save();
        canvas.translate(sunCenter.dx, sunCenter.dy);
        canvas.rotate(time * math.pi * 4); // Slow rotation
        for (int i=0; i<8; i++) {
           canvas.save();
           canvas.rotate(i * math.pi / 4);
           canvas.drawLine(Offset(0, sunRadius + 10), Offset(0, sunRadius + 60 + math.sin(time * math.pi * 20)*10), rayPaint);
           canvas.restore();
        }
        canvas.restore();
      }

      // Morph Bottom-Right AQI -> Soft foreground cloud
      final cloudCenter = Offset.lerp(aqiBottomRight, Offset(180, size.height - 300), transition)!;
      final cloudW = ui.lerpDouble(aqiBottomRightRadius * 2, 600, transition)!;
      final cloudColor = Color.lerp(c2.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.7), transition)!;
      
      _drawStylizedCloud(canvas, cloudCenter, cloudW, cloudColor, transition);

    } else if (isCloudy) {
       // Cloud morphing
       final cloud1Center = Offset.lerp(aqiTopLeft, Offset(120, 150), transition)!;
       final cloud1R = ui.lerpDouble(aqiTopLeftRadius, 180, transition)!;
       final c1Color = Color.lerp(c1.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.9), transition)!;
       _drawStylizedCloud(canvas, cloud1Center, cloud1R * 2, c1Color, transition);

       final cloud2Center = Offset.lerp(aqiBottomRight, Offset(size.width - 150, 320), transition)!;
       final cloud2R = ui.lerpDouble(aqiBottomRightRadius, 250, transition)!;
       final c2Color = Color.lerp(c2.withValues(alpha: 0.15), const Color(0xFFE2E8F0).withValues(alpha: 0.8), transition)!;
       _drawStylizedCloud(canvas, cloud2Center, cloud2R * 2, c2Color, transition);
    } else if (isRain) {
       // Rain morphing
       final cloud1Center = Offset.lerp(aqiTopLeft, Offset(size.width/2, 100), transition)!;
       final cloud1R = ui.lerpDouble(aqiTopLeftRadius, size.width * 0.45, transition)!;
       final c1Color = Color.lerp(c1.withValues(alpha: 0.15), const Color(0xFF94A3B8).withValues(alpha: 0.8), transition)!;
       _drawStylizedCloud(canvas, cloud1Center, cloud1R * 2, c1Color, transition);

       final cloud2Center = Offset.lerp(aqiBottomRight, Offset(size.width - 100, 250), transition)!;
       final cloud2R = ui.lerpDouble(aqiBottomRightRadius, 200, transition)!;
       final c2Color = Color.lerp(c2.withValues(alpha: 0.15), const Color(0xFF64748B).withValues(alpha: 0.6), transition)!;
       _drawStylizedCloud(canvas, cloud2Center, cloud2R * 2, c2Color, transition);
       
       // Large rain streaks and lightning removed per user request
    } else {
       // Snow morphing
       final cloud1Center = Offset.lerp(aqiTopLeft, Offset(size.width/2, 150), transition)!;
       final cloud1R = ui.lerpDouble(aqiTopLeftRadius, size.width * 0.5, transition)!;
       final c1Color = Color.lerp(c1.withValues(alpha: 0.15), const Color(0xFFDBEAFE).withValues(alpha: 0.8), transition)!;
       _drawStylizedCloud(canvas, cloud1Center, cloud1R * 2, c1Color, transition);

       final cloud2Center = Offset.lerp(aqiBottomRight, Offset(size.width - 200, 350), transition)!;
       final cloud2R = ui.lerpDouble(aqiBottomRightRadius, 250, transition)!;
       final c2Color = Color.lerp(c2.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.7), transition)!;
       _drawStylizedCloud(canvas, cloud2Center, cloud2R * 2, c2Color, transition);
    }
  }

  void _drawStylizedCloud(Canvas canvas, Offset center, double width, Color color, double transition) {
     final floatOffset = math.sin(time * math.pi * 10) * 8 * transition;
     final c = Offset(center.dx, center.dy + floatOffset);

     final r1 = ui.lerpDouble(width/2, width * 0.28, transition)!;
     final r2 = ui.lerpDouble(width/2, width * 0.40, transition)!;
     final r3 = ui.lerpDouble(width/2, width * 0.22, transition)!;

     final d1 = Offset.lerp(Offset.zero, Offset(-width * 0.25, 20), transition)!;
     final d2 = Offset.lerp(Offset.zero, Offset.zero, transition)!;
     final d3 = Offset.lerp(Offset.zero, Offset(width * 0.30, 30), transition)!;

     if (transition > 0) {
       final shadow = Paint()
         ..color = Colors.black.withValues(alpha: 0.12 * transition)
         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
       canvas.drawCircle(c + d1, r1, shadow);
       canvas.drawCircle(c + d2, r2, shadow);
       canvas.drawCircle(c + d3, r3, shadow);
     }

     final paint = Paint()..color = color;
     canvas.drawCircle(c + d1, r1, paint);
     canvas.drawCircle(c + d2, r2, paint);
     canvas.drawCircle(c + d3, r3, paint);

     if (transition > 0) {
       final highlight = Paint()
         ..shader = ui.Gradient.linear(
           Offset(c.dx, c.dy - width * 0.3),
           Offset(c.dx, c.dy),
           [
             Colors.white.withValues(alpha: 0.6 * transition),
             Colors.white.withValues(alpha: 0.0),
           ]
         );
       canvas.drawCircle(c + d1, r1, highlight);
       canvas.drawCircle(c + d2, r2, highlight);
       canvas.drawCircle(c + d3, r3, highlight);
     }
  }

  void _drawStaticDecorations(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-60, size.height * 0.85), 200, p1);

    final p2 = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width + 80, size.height * 0.4), 180, p2);

    final p3 = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.6), 100, p3);
    
    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    canvas.drawLine(Offset(0, size.height * 0.28), Offset(size.width, size.height * 0.18), linePaint);
    canvas.drawLine(Offset(0, size.height * 0.32), Offset(size.width, size.height * 0.22), linePaint);
  }

  @override
  bool shouldRepaint(covariant AtmosphericBackgroundPainter oldDelegate) => true;
}

class WeatherParticleEmitter extends StatefulWidget {
  final bool isSnowing;
  final bool isRaining;

  const WeatherParticleEmitter({super.key, required this.isSnowing, required this.isRaining});

  @override
  State<WeatherParticleEmitter> createState() => _WeatherParticleEmitterState();
}

class _WeatherParticleEmitterState extends State<WeatherParticleEmitter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _initParticles();
  }
  
  @override
  void didUpdateWidget(covariant WeatherParticleEmitter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRaining != widget.isRaining || oldWidget.isSnowing != widget.isSnowing) {
      _initParticles();
    }
  }

  void _initParticles() {
    _particles.clear();
    int count = widget.isRaining ? 100 : (widget.isSnowing ? 60 : 0);
    for (int i = 0; i < count; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: (widget.isRaining ? 0.8 : 0.2) + _random.nextDouble() * 0.5,
        size: widget.isRaining ? (2.0 + _random.nextDouble() * 2) : (3.0 + _random.nextDouble() * 4),
      ));
    }
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
      builder: (context, _) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            isRain: widget.isRaining,
          ),
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double size;
  Particle({required this.x, required this.y, required this.speed, required this.size});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool isRain;

  ParticlePainter({required this.particles, required this.isRain});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRain ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.8)
      ..style = isRain ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = isRain ? 1.5 : 0;

    for (var p in particles) {
      p.y += p.speed * 0.02;
      if (isRain) {
        p.x -= 0.005; // Slight wind
      } else {
        p.x += math.sin(p.y * 10) * 0.002; // Drifting snow
      }
      
      if (p.y > 1.1) p.y = -0.1;
      if (p.x < -0.1) p.x = 1.1;
      if (p.x > 1.1) p.x = -0.1;

      final px = p.x * size.width;
      final py = p.y * size.height;

      if (isRain) {
        canvas.drawLine(Offset(px, py), Offset(px - 5, py + 15), paint);
      } else {
        canvas.drawCircle(Offset(px, py), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

// ---------------------------------------------------------
// AQI GAUGE PAINTER
// ---------------------------------------------------------

class AqiGaugePainter extends CustomPainter {
  final double value;
  final Color activeColor;

  final Paint _trackPaint = Paint()
    ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.5)
    ..strokeWidth = 12
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final Paint _fgPaint = Paint()
    ..strokeWidth = 12
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  AqiGaugePainter({required this.value, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 8;
    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, _trackPaint);

    final activeSweep = sweepAngle * value;
    
    if (value > 0) {
      _fgPaint.color = activeColor;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeSweep, false, _fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AqiGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.activeColor != activeColor;
  }
}
