import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import '../services/nasa_service.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_state.dart';
import '../widgets/error_state.dart';
import '../widgets/apod_hero_card.dart';
import 'apod_detail_screen.dart';

class CosmicLensScreen extends StatefulWidget {
  const CosmicLensScreen({super.key});

  @override
  State<CosmicLensScreen> createState() => _CosmicLensScreenState();
}

class _CosmicLensScreenState extends State<CosmicLensScreen> {
  final NasaService _nasaService = NasaService();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  ApodModel? _todayApod;
  List<ApodModel> _previousApods = [];
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
        _nasaService.fetchApod(),
        _nasaService.fetchApodRange(),
      ]);

      if (mounted) {
        setState(() {
          _todayApod = results[0] as ApodModel;
          _previousApods = results[1] as List<ApodModel>;
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

  Widget _buildGridCard(ApodModel apod, double height) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ApodDetailScreen(apod: apod),
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: height,
          color: const Color(0xFF1A1A24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (apod.mediaType == 'video')
                const Icon(Icons.play_circle_outline, color: Colors.white54, size: 48)
              else
                Image.network(apod.url, fit: BoxFit.cover),
              Positioned(
                bottom: 0, left: 0, right: 0,
                height: height * 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, const Color(0xFF0A0A0C).withOpacity(0.9)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Archive', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      apod.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      apod.date,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF8B5CF6);

    return Container(
      decoration: AppTheme.spaceBackground,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0C).withOpacity(0.5),
        body: Column(
          children: [
            // App Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Hero(
                      tag: 'cosmic_lens_hero',
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.black.withOpacity(0.3),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'COSMIC LENS',
                      style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? accentColor : Colors.white,
                      ),
                      onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const LoadingState(accentColor: accentColor)
                  : _error != null
                      ? ErrorState(accentColor: accentColor, message: _error!, onRetry: _loadData)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_todayApod != null)
                                ApodHeroCard(
                                  apod: _todayApod!,
                                  isLive: true,
                                  heroTag: 'today_hero',
                                ),
                              
                              const SizedBox(height: 32),
                              
                              // Section Header
                              if (_previousApods.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'PREVIOUS DAYS',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text('VIEW ALL', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Grid
                                if (_previousApods.isNotEmpty)
                                  _buildGridCard(_previousApods[0], 220),
                                const SizedBox(height: 16),
                                if (_previousApods.length > 1)
                                  Row(
                                    children: [
                                      Expanded(child: _buildGridCard(_previousApods[1], 250)),
                                      const SizedBox(width: 16),
                                      if (_previousApods.length > 2)
                                        Expanded(child: _buildGridCard(_previousApods[2], 250))
                                      else
                                        Expanded(child: Container()),
                                    ],
                                  ),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
