import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import '../services/nasa_service.dart';
import '../theme/app_theme.dart';

class CosmicLensScreen extends StatefulWidget {
  const CosmicLensScreen({super.key});

  @override
  State<CosmicLensScreen> createState() => _CosmicLensScreenState();
}

class _CosmicLensScreenState extends State<CosmicLensScreen> {
  final NasaService _nasaService = NasaService();
  ApodModel? _apod;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApod();
  }

  Future<void> _loadApod() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apod = await _nasaService.fetchApod();
      setState(() {
        _apod = apod;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF8B5CF6);
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
                      onPressed: _loadApod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: nearBlack,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_apod != null)
              ...[
                // Image or Video Content
                if (_apod!.mediaType == 'video')
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E103C).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam, color: accentColor, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Today\'s APOD is a Video',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please visit NASA\'s website to view it.',
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Hero(
                      tag: 'cosmic_lens_hero',
                      child: Image.network(
                        _apod!.url,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Gradient Scrim for Image
                if (_apod!.mediaType != 'video')
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            nearBlack,
                          ],
                        ),
                      ),
                    ),
                  ),

                // Frosted glass panel sliding up from bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C0C18).withOpacity(0.78),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          border: Border(
                            top: BorderSide(color: accentColor.withOpacity(0.25), width: 1.5),
                            left: BorderSide(color: accentColor.withOpacity(0.25), width: 1.5),
                            right: BorderSide(color: accentColor.withOpacity(0.25), width: 1.5),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _apod!.date,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _apod!.title,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _apod!.explanation,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

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
