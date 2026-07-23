import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/history_event_model.dart';
import '../services/wiki_service.dart';
import '../services/connectivity_service.dart';

import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/frosted_back_button.dart';
import '../services/app_data_store.dart';

class EchoesScreen extends StatefulWidget {
  const EchoesScreen({super.key});

  @override
  State<EchoesScreen> createState() => _EchoesScreenState();
}

class _EchoesScreenState extends State<EchoesScreen> {
  final WikiService _wikiService = WikiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<HistoryEventModel>? _events;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final store = AppDataStore();
    if (store.historyEvents != null) {
      if (mounted) {
        setState(() {
          _events = store.historyEvents;
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
      final events = await _wikiService.fetchOnThisDayEvents();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF06B6D4);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: Material(
              color: Color(0xFF0A0A12),
              child: SizedBox.expand(),
            ),
          ),
          // States
          if (_isLoading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 72.0, right: 24.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLoader(width: 80, height: 16),
                        SizedBox(height: 8),
                        SkeletonLoader(width: 200, height: 32),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32.0, top: 8.0),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 72,
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),
                                  const SkeletonLoader(width: 48, height: 24, borderRadius: 12),
                                  if (index < 3)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.white.withValues(alpha: 0.1),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: 24.0, bottom: 24.0),
                                child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          else if (_error != null)
            ErrorState(
              accentColor: accentColor,
              message: _error!,
              onRetry: _loadEvents,
            )
          else if (_events != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fixed Header
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 72.0, right: 24.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFormattedDate(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'On This Day',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Timeline List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32.0, top: 8.0),
                    itemCount: _events!.length,
                    itemBuilder: (context, index) {
                      final event = _events![index];
                      final bool isLast = index == _events!.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline column
                            SizedBox(
                              width: 72,
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 24),
                                    width: 48,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      event.year,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              accentColor.withValues(alpha: 0.5),
                                              accentColor.withValues(alpha: 0.1),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Content Card
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 24.0, bottom: 24.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              event.text,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                          if (event.pageThumbnailUrl != null) ...[
                                            const SizedBox(width: 16),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                event.pageThumbnailUrl!,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          // Safe-area aware back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: const FrostedBackButton(heroTag: 'echoes_back_hero'),
            ),
          ),
        ],
      ),
    );
  }
}
