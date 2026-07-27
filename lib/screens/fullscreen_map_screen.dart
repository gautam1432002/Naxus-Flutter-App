import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/iss_model.dart';
import '../widgets/tactile_glass_button.dart';

class FullscreenMapScreen extends StatelessWidget {
  final IssModel issPosition;

  const FullscreenMapScreen({super.key, required this.issPosition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Hero(
        tag: 'orbit_map',
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF040B16), // Dark background matching space
            borderRadius: BorderRadius.zero,
          ),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(issPosition.latitude, issPosition.longitude),
                  initialZoom: 4.5,
                  minZoom: 2,
                  maxZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.nexus',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(issPosition.latitude, issPosition.longitude),
                        width: 60,
                        height: 60,
                        child: _StaticSatelliteMarker(),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap, © CARTO',
                      ),
                    ],
                  ),
                ],
              ),
              
              // Top Overlay gradient for button visibility
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Back Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TactileGlassButton(
                    icon: Icons.close,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticSatelliteMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF06B6D4), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.satellite_alt,
            color: Color(0xFF06B6D4),
            size: 14,
          ),
        ),
      ],
    );
  }
}
