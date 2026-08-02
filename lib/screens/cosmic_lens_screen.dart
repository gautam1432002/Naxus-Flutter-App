import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import '../services/nasa_service.dart';
import '../models/data_result.dart';

import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/apod_hero_card.dart';
import '../services/app_data_store.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../widgets/tactile_glass_button.dart';
import '../widgets/nexus_universal_header.dart';
import '../widgets/glass_container.dart';

class CosmicLensScreen extends StatefulWidget {
  const CosmicLensScreen({super.key});

  @override
  State<CosmicLensScreen> createState() => _CosmicLensScreenState();
}

class _CosmicLensScreenState extends State<CosmicLensScreen> {
  final NasaService _nasaService = NasaService();
  
  ApodModel? _todayApod;
  List<ApodModel> _previousApods = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final store = AppDataStore();
    if (store.todayApod != null && store.previousApods != null) {
      if (mounted) {
        setState(() {
          _todayApod = store.todayApod;
          _previousApods = store.previousApods!.where((a) => a.date != _todayApod!.date).toList();
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
        _nasaService.fetchApod(),
        _nasaService.fetchApodRange(),
      ]);

      if (mounted) {
        setState(() {
          final todayResult = results[0] as DataResult<ApodModel>;
          final rangeResult = results[1] as DataResult<List<ApodModel>>;
          
          _todayApod = todayResult.data;
          store.todayApod = _todayApod;
          
          final allPrevious = rangeResult.data;
          store.previousApods = allPrevious;
          _previousApods = allPrevious.where((a) => a.date != _todayApod!.date).toList();
          
          _isOffline = todayResult.isOffline || rangeResult.isOffline;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _todayApod == null) {
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
        HapticFeedback.lightImpact();
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Material(
                  type: MaterialType.transparency,
                  child: ApodHeroCard(
                    apod: apod,
                    isLive: false,
                    heroTag: 'apod_dialog_${apod.date}',
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
          boxShadow: AppTheme.bentoShadow,
        ),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          blurSigma: 8.0,
          overlayColor: Colors.transparent,
          borderColor: Colors.transparent,
          child: Stack(
              fit: StackFit.expand,
              children: [
                if (apod.isVideo) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      apod.youtubeThumbnail ?? 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2072&auto=format&fit=crop',
                      cacheWidth: 1080,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                ] else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      apod.url,
                      cacheWidth: 1080,
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
                        GridView.builder(
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
                            return _buildGridCard(_previousApods[index], 250);
                          },
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
