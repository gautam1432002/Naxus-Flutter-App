import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import '../theme/app_theme.dart';
import '../widgets/apod_hero_card.dart';
import '../widgets/nexus_universal_header.dart';

class ApodDetailScreen extends StatelessWidget {
  final ApodModel apod;

  const ApodDetailScreen({super.key, required this.apod});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: AppTheme.spaceBackground),
          ),
          // Background ambient lighting (Top Right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.08), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),
          
          CustomScrollView(
             slivers: [
                const SliverSafeArea(
                   bottom: false,
                   sliver: SliverToBoxAdapter(child: SizedBox(height: 72)),
                ),
                SliverPadding(
                   padding: const EdgeInsets.all(16),
                   sliver: SliverToBoxAdapter(
                      child: ApodHeroCard(
                         apod: apod,
                         isLive: false,
                         heroTag: 'apod_hero_${apod.date}',
                      ),
                   ),
                ),
             ],
          ),

          // Floating Nav (Universal)
          NexusUniversalHeader(
            onBack: () => Navigator.of(context).pop(),
            center: const Text(
              'ARCHIVE',
              style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
