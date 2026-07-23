import 'package:flutter/material.dart';
import '../models/apod_model.dart';
import '../theme/app_theme.dart';
import '../widgets/apod_hero_card.dart';
import '../widgets/frosted_back_button.dart';

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
                    const FrostedBackButton(heroTag: 'apod_detail_back_hero'),
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
                  heroTag: 'apod_hero_${apod.date}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
