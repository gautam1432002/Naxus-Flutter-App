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
          backgroundColor: const Color(0xFF0F172A),
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
              _isLoading = true;
            });
            _fetchData();
          }
        },
      ),
    );
  }

  Color _getAqiColor(double aqi) {
    if (aqi <= 33) return const Color(0xFF0284C7); // Cyan
    if (aqi <= 66) return const Color(0xFFD97706); // Amber
    return const Color(0xFFE11D48); // Coral/Red
  }

  String _getAqiLabel(double aqi) {
    if (aqi <= 33) return 'Good';
    if (aqi <= 66) return 'Moderate';
    return 'Poor';
  }
  
  List<Color> _getBackgroundGlowColors(double aqi) {
    if (aqi <= 33) return const [Color(0xFF0284C7), Color(0xFF0D9488)]; // Clear
    if (aqi <= 66) return const [Color(0xFFD97706), Color(0xFF6366F1)]; // Moderate
    return const [Color(0xFFE11D48), Color(0xFFEA580C)]; // Poor
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
              color: Colors.white.withValues(alpha: 0.75),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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

  Widget _buildAqiStatCard(String title, double value, String unit, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.75),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
  
  Widget _buildDashboard() {
    if (_weather == null || _airQuality == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          // Weather Summary Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withValues(alpha: 0.75),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weather!.temperature.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Feels like ${_weather!.feelsLike.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(_weather!.conditionIcon, color: const Color(0xFF0284C7), size: 48),
                          const SizedBox(height: 8),
                          Text(
                            _weather!.conditionLabel,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 24),

          // AQI Gauge Hero Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withValues(alpha: 0.75),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: _airQuality!.europeanAqi),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, aqiVal, child) {
                        final normalizedValue = math.min(aqiVal / 100.0, 1.0);
                        final activeColor = _getAqiColor(aqiVal);

                        return SizedBox(
                          width: double.infinity,
                          height: 260,
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
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 64,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                  Text(
                                    _getAqiLabel(aqiVal).toUpperCase(),
                                    style: TextStyle(
                                      color: activeColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'AQI INDEX',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
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
                  ),
                ),
              ),
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
              _buildAqiStatCard('PM2.5', _airQuality!.pm2_5, 'µg/m³', Icons.masks_outlined),
              const SizedBox(width: 16),
              _buildAqiStatCard('PM10', _airQuality!.pm10, 'µg/m³', Icons.blur_on),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAqi = _airQuality?.europeanAqi ?? 10.0;
    final glowColors = _getBackgroundGlowColors(currentAqi);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Dynamic Atmospheric Lighting (Top Left)
          Positioned(
            top: -100,
            left: -100,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(begin: glowColors[0], end: glowColors[0]),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeInOut,
              builder: (context, color, child) {
                return Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color?.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(color: color!.withValues(alpha: 0.12), blurRadius: 100, spreadRadius: 50)
                    ]
                  ),
                );
              },
            ),
          ),
          // Dynamic Atmospheric Lighting (Bottom Right)
          Positioned(
            bottom: -100,
            right: -100,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(begin: glowColors[1], end: glowColors[1]),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeInOut,
              builder: (context, color, child) {
                return Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color?.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(color: color!.withValues(alpha: 0.12), blurRadius: 100, spreadRadius: 50)
                    ]
                  ),
                );
              },
            ),
          ),
          
          Column(
            children: [
              // Header area
              SafeArea(
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

              // Title Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _currentLocation?.name ?? 'Air Pulse',
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
                    if (_weather != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'LIVE METRICS',
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
              ),
              
              if (_currentLocation?.country != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Align(
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
                ),
                
              const SizedBox(height: 16),

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
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await _locationStorageService.saveLastLocation(loc);
                            if (mounted) {
                              setState(() {
                                _currentLocation = loc;
                                _isLoading = true; // Trigger fade through
                              });
                              _fetchData();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF0F172A) 
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.transparent 
                                    : Colors.white,
                                width: 1.5,
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
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
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
                
              const SizedBox(height: 8),

              // Main Content Area with PageTransitionSwitcher
              Expanded(
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
        ],
      ),
    );
  }
  
  Widget _buildDashboardContent() {
    if (_isLoading) {
      return SingleChildScrollView(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const SkeletonLoader(width: double.infinity, height: 160, borderRadius: 28),
            const SizedBox(height: 24),
            const SkeletonLoader(width: double.infinity, height: 260, borderRadius: 28),
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
            const SizedBox(height: 32),
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
      return Container(key: const ValueKey('empty'), child: _buildEmptyState());
    }
    
    if (_weather != null && _airQuality != null) {
      return Container(key: const ValueKey('dashboard'), child: _buildDashboard());
    }
    
    return const SizedBox.shrink(key: ValueKey('none'));
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
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ]
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
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
                      tileColor: Colors.white,
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
    );
  }
}

class AqiGaugePainter extends CustomPainter {
  final double value;
  final Color activeColor;

  final Paint _trackPaint = Paint()
    ..color = const Color(0xFFE2E8F0) // Slate-200
    ..strokeWidth = 24
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final Paint _glowPaint = Paint()
    ..strokeWidth = 36
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

  final Paint _fgPaint = Paint()
    ..strokeWidth = 24
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  AqiGaugePainter({required this.value, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 16;
    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, _trackPaint);

    final activeSweep = sweepAngle * value;
    
    if (value > 0) {
      _glowPaint.color = activeColor.withValues(alpha: 0.35);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeSweep, false, _glowPaint);

      _fgPaint.color = activeColor;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeSweep, false, _fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AqiGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.activeColor != activeColor;
  }
}
