import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/history_event_model.dart';
import '../services/wiki_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_state.dart';
import '../widgets/tactile_glass_button.dart';
import '../widgets/nexus_universal_header.dart';
import '../services/app_data_store.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/glass_container.dart';

class EchoesScreen extends StatefulWidget {
  const EchoesScreen({super.key});

  @override
  State<EchoesScreen> createState() => _EchoesScreenState();
}

class _EchoesScreenState extends State<EchoesScreen> {
  final WikiService _wikiService = WikiService();
  List<HistoryEventModel>? _events;
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;
  int? _expandedIndex;
  final Map<int, GlobalKey> _itemKeys = {};

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
      return; // Do not refetch if we already have it
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final eventsResult = await _wikiService.fetchOnThisDayEvents();
      store.historyEvents = eventsResult.data; // Manage data properly in the store
      if (mounted) {
        setState(() {
          _events = eventsResult.data;
          _isOffline = eventsResult.isOffline;
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark cosmic theme
      body: Stack(
        children: [
          // Background ambient lighting (Top Right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.08), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),
          // Background ambient lighting (Bottom Left)
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.08), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),
          
          // Main Scroll View
          AnimationLimiter(
            child: CustomScrollView(
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24.0, 
                    right: 24.0, 
                    top: MediaQuery.paddingOf(context).top + 60.0, 
                    bottom: 16.0
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_stories, color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _getFormattedDate(),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'On This Day\nin History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Wikipedia Relay Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.public, size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 6),
                            Text(
                              'Verified by Wikipedia',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      children: List.generate(4, (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonLoader(width: 60, height: 24, borderRadius: 12),
                            SizedBox(width: 16),
                            Expanded(child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: 24)),
                          ],
                        ),
                      )),
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ErrorState(
                      accentColor: const Color(0xFF06B6D4),
                      message: _error!,
                      onRetry: _loadEvents,
                    ),
                  ),
                )
              else if (_events != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = _events![index];
                        final isLast = index == _events!.length - 1;
                        final isExpanded = _expandedIndex == index;
                        final itemKey = _itemKeys.putIfAbsent(index, () => GlobalKey());

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 450),
                          child: SlideAnimation(
                            horizontalOffset: 60.0,
                            child: FadeInAnimation(
                              key: itemKey,
                              child: _ChronoSpineRow(
                                event: event,
                                isLast: isLast,
                                isExpanded: isExpanded,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedIndex = null;
                                    } else {
                                      _expandedIndex = index;
                                      Future.delayed(const Duration(milliseconds: 150), () {
                                        if (itemKey.currentContext != null) {
                                          Scrollable.ensureVisible(
                                            itemKey.currentContext!,
                                            alignment: 0.5,
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeInOutCubic,
                                          );
                                        }
                                      });
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _events!.length,
                    ),
                  ),
                )
            ],
          ),
          ),
          
          // Universal Header Layer
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
                icon: Icons.calendar_today,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // For now just refresh
                  _loadEvents();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChronoSpineRow extends StatelessWidget {
  final HistoryEventModel event;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ChronoSpineRow({
    required this.event,
    required this.isLast,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (The Spine & Node)
          SizedBox(
            width: 72,
            child: Column(
              children: [
                const SizedBox(height: 16), 
                // Orbital Node Dot
                AnimatedScale(
                  scale: isExpanded ? 1.25 : 1.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isExpanded ? const Color(0xFF06B6D4) : const Color(0xFF475569),
                      boxShadow: isExpanded ? [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Year Badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isExpanded 
                        ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)])
                        : const LinearGradient(colors: [Color(0xFF334155), Color(0xFF475569)]),
                  ),
                  child: Text(
                    event.year,
                    style: TextStyle(
                      color: isExpanded ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Spine line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 8),
                      color: const Color(0xFF334155),
                    ),
                  ),
                if (isLast)
                   const SizedBox(height: 24),
              ],
            ),
          ),

          // Right Column (Liquid Glass Card)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    border: Border.all(
                      color: isExpanded ? const Color(0xFF06B6D4) : Colors.white.withValues(alpha: 0.05),
                      width: isExpanded ? 2.0 : 1.0,
                    ),
                  ),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(28),
                    blurSigma: 8.0,
                    overlayColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    child: AnimatedSize(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.text,
                                      style: const TextStyle(
                                        color: Color(0xFFF1F5F9),
                                        fontSize: 15,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: isExpanded ? null : 2,
                                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isExpanded && event.pageThumbnailUrl != null) ...[
                                    const SizedBox(width: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        event.pageThumbnailUrl!,
                                        cacheWidth: 1080,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 16),
                                if (event.pageThumbnailUrl != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      event.pageThumbnailUrl!,
                                      cacheWidth: 1080,
                                      width: double.infinity,
                                      fit: BoxFit.fitWidth,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.open_in_new, size: 14, color: Color(0xFF06B6D4)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Read on Wikipedia',
                                        style: TextStyle(
                                          color: Color(0xFF06B6D4),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
            ),
          ),
        ],
      ),
    );
  }
}


