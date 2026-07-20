import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import '../theme/app_theme.dart';
import '../widgets/apod_hero_card.dart';

class ApodDetailScreen extends StatelessWidget {
  final ApodModel apod;

  const ApodDetailScreen({super.key, required this.apod});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.spaceBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // App Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    ClipOval(
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'ARCHIVE',
                          style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ApodHeroCard(
                  apod: apod,
                  isLive: false,
                  heroTag: 'archive_${apod.date}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
