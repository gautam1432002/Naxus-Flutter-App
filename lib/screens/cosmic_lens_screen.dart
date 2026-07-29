import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import '../services/nasa_service.dart';
import '../services/connectivity_service.dart';

import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/apod_hero_card.dart';
import 'apod_detail_screen.dart';
import '../services/app_data_store.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../widgets/tactile_glass_button.dart';
import '../widgets/nexus_universal_header.dart';

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
    final store = AppDataStore();
    if (store.todayApod != null) {
      if (mounted) {
        setState(() {
          _todayApod = store.todayApod;
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
        _nasaService.fetchApod(),
        _nasaService.fetchApodRange(),
      ]);

      if (mounted) {
        setState(() {
          _todayApod = results[0] as ApodModel;
          
          // Filter out today's APOD in case of timezone overlap
          final allPrevious = results[1] as List<ApodModel>;
          _previousApods = allPrevious.where((a) => a.date != _todayApod!.date).toList();
          
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
    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 600),
      openBuilder: (context, _) => ApodDetailScreen(apod: apod),
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      middleColor: Colors.transparent,
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
              boxShadow: AppTheme.bentoShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (apod.mediaType == 'video')
                      const Icon(Icons.play_circle_outline, color: Colors.white54, size: 48)
                    else
                      Hero(
                        tag: 'apod_hero_${apod.date}',
                        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: toHeroContext.widget,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Image.network(
                            apod.url,
                            fit: BoxFit.cover,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: child,
                              );
                            },
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: height * 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, const Color(0xFF0A0E27).withValues(alpha: 0.95)],
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
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: AppTheme.spaceBackground),
          ),
          // Cosmic Background Blur Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),
          // Full Screen Scrollable Content
          CustomScrollView(
            slivers: [
              const SliverSafeArea(
                bottom: false,
                sliver: SliverToBoxAdapter(
                  child: SizedBox(height: 72), // Space for floating nav
                ),
              ),
              
              // Header Title
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Cosmic Lens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              
              // Content
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLoader(width: double.infinity, height: 380, borderRadius: 24),
                        const SizedBox(height: 32),
                        const SkeletonLoader(width: 150, height: 24),
                        const SizedBox(height: 16),
                        const SkeletonLoader(width: double.infinity, height: 220, borderRadius: 16),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(child: SkeletonLoader(width: double.infinity, height: 250, borderRadius: 16)),
                            SizedBox(width: 16),
                            Expanded(child: SkeletonLoader(width: double.infinity, height: 250, borderRadius: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: ErrorState(accentColor: accentColor, message: _error!, onRetry: _loadData),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_todayApod != null)
                        ApodHeroCard(
                          apod: _todayApod!,
                          isLive: true,
                          heroTag: 'apod_hero_${_todayApod!.date}',
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Section Header
                      if (_previousApods.isNotEmpty) ...[
                        const Text(
                          'PREVIOUS DAYS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        
                        // Grid
                        AnimationLimiter(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _previousApods.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredGrid(
                                position: index,
                                duration: const Duration(milliseconds: 400),
                                columnCount: 2,
                                child: ScaleAnimation(
                                  scale: 0.9,
                                  curve: Curves.easeOutCubic,
                                  child: FadeInAnimation(
                                    child: _buildGridCard(_previousApods[index], 250),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
            ],
          ),

          // Floating Navigation Row (Universal)
          NexusUniversalHeader(
            onBack: () => Navigator.of(context).pop(),
            actions: [
              TactileGlassButton(
                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                iconColor: _isFavorite ? accentColor : Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
