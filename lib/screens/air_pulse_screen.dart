import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
import '../widgets/tactile_glass_button.dart';
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
  final ConnectivityService _connectivityService = ConnectivityService();

  LocationModel? _currentLocation;
  List<LocationModel> _savedLocations = [];

  AirQualityModel? _airQuality;
  WeatherModel? _weather;
  bool _isLoading = true;
  String? _error;
  ActiveDashboardCard _activeCard = ActiveDashboardCard.weather;

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
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeLocation(LocationModel loc) async {
    await _locationStorageService.removeSavedLocation(loc);
    await _loadSavedLocations();
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
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
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
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
              color: Colors.white.withValues(alpha: 0.20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
          color: Colors.white.withValues(alpha: 0.20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
              ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]
              : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: isActive ? 0.35 : 0.15), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.08 : 0.02),
              blurRadius: isActive ? 30 : 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Stack(
              children: [
                // Custom weather illustration
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.5,
                    child: WeatherIllustration(
                      conditionLabel: _weather!.conditionLabel,
                      isDay: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_weather!.temperature.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Feels like ${_weather!.feelsLike.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _weather!.conditionLabel,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
              ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]
              : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: isActive ? 0.35 : 0.15), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.08 : 0.02),
              blurRadius: isActive ? 30 : 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
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

          // Layer 2: Fixed Hovering Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    TactileGlassButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (_currentLocation != null)
                      TactileGlassButton(
                        icon: Icons.star_border,
                        onTap: _saveCurrentLocation,
                      ),
                    const SizedBox(width: 12),
                    TactileGlassButton(
                      icon: Icons.search,
                      onTap: _openSearchSheet,
                    ),
                  ],
                ),
              ),
            ),
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
        color: const Color(0xFFF8FAFC).withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ]
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24, top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TextField(
                autofocus: true,
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0284C7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final loc = _searchResults[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: Colors.white.withValues(alpha: 0.5),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_city, color: Color(0xFF64748B)),
                          ),
                          title: Text(loc.name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                          subtitle: Text(loc.country, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelect(loc);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ATMOSPHERIC BACKGROUND (Dynamic Sky & Weather Particles)
// ---------------------------------------------------------

class AtmosphericBackground extends StatelessWidget {
  final WeatherModel? weather;
  final AirQualityModel? airQuality;
  final ActiveDashboardCard? activeCard;

  const AtmosphericBackground({super.key, this.weather, this.airQuality, this.activeCard});

  @override
  Widget build(BuildContext context) {
    // Determine colors
    Color topLeftColor = const Color(0xFFFB923C); // Default clear orange
    Color bottomRightColor = const Color(0xFFF8FAFC); // Default white
    bool isRaining = false;
    bool isSnowing = false;

    if (activeCard == ActiveDashboardCard.aqi && airQuality != null) {
      // AQI Mode Override
      final aqi = airQuality!.europeanAqi;
      if (aqi <= 33) {
        topLeftColor = const Color(0xFF34D399); // Green
        bottomRightColor = const Color(0xFF60A5FA); // Blue
      } else if (aqi <= 66) {
        topLeftColor = const Color(0xFFFACC15); // Yellow
        bottomRightColor = const Color(0xFFF97316); // Orange
      } else {
        topLeftColor = const Color(0xFFEF4444); // Red
        bottomRightColor = const Color(0xFFEA580C); // Orange
      }
    } else if (weather != null) {
      // Weather Mode (for Good AQI or missing AQI)
      final label = weather!.conditionLabel.toLowerCase();
      if (label.contains('rain') || label.contains('drizzle') || label.contains('thunder')) {
        isRaining = true;
        topLeftColor = const Color(0xFF64748B); // Slate
        bottomRightColor = const Color(0xFF94A3B8); // Light Slate
      } else if (label.contains('snow')) {
        isSnowing = true;
        topLeftColor = const Color(0xFF93C5FD);
        bottomRightColor = const Color(0xFFF8FAFC);
      } else if (label.contains('cloud')) {
        topLeftColor = const Color(0xFF93C5FD);
        bottomRightColor = const Color(0xFFF8FAFC);
      } else {
        // Clear Weather
        topLeftColor = const Color(0xFFFB923C); // Warm sunlight orange
        bottomRightColor = const Color(0xFFF8FAFC); // Soft cloud white
      }
    } else if (airQuality != null && airQuality!.europeanAqi <= 33) {
      // If we only have AQI and it's Good
      topLeftColor = const Color(0xFF10B981); // Green
      bottomRightColor = const Color(0xFF3B82F6); // Blue
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          // Dynamic gradient spots
          Positioned(
            top: -150,
            left: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: topLeftColor.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: topLeftColor.withValues(alpha: 0.15), blurRadius: 150, spreadRadius: 80)
                ]
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bottomRightColor.withValues(alpha: 0.20),
                boxShadow: [
                  BoxShadow(color: bottomRightColor.withValues(alpha: 0.20), blurRadius: 150, spreadRadius: 80)
                ]
              ),
            ),
          ),
          
          // Mountain silhouette for snow
          if (isSnowing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: CustomPaint(
                painter: MountainSilhouettePainter(),
              ),
            ),

          // Weather Particles Engine
          if (isRaining || isSnowing)
            Positioned.fill(
              child: WeatherParticleEmitter(
                isSnowing: isSnowing,
                isRaining: isRaining,
              ),
            ),
            
          // High blur to keep it ambient
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

class MountainSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.3, size.width * 0.3, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width * 0.7, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.1, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
