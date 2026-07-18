import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/history_event_model.dart';
import '../services/wiki_service.dart';
import '../theme/app_theme.dart';

class EchoesScreen extends StatefulWidget {
  const EchoesScreen({super.key});

  @override
  State<EchoesScreen> createState() => _EchoesScreenState();
}

class _EchoesScreenState extends State<EchoesScreen> {
  final WikiService _wikiService = WikiService();
  List<HistoryEventModel>? _events;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
                      onPressed: _loadEvents,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: nearBlack,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Hero(
                            tag: 'echoes_hero',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                'On This Day',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                        color: accentColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: accentColor.withOpacity(0.3)),
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
                                                accentColor.withOpacity(0.5),
                                                accentColor.withOpacity(0.1),
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
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event.text,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.white.withOpacity(0.9),
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
