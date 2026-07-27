import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

class ApodVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ApodVideoPlayer({super.key, required this.videoUrl});

  @override
  State<ApodVideoPlayer> createState() => _ApodVideoPlayerState();
}

class _ApodVideoPlayerState extends State<ApodVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    _checkVideoSource();
  }

  void _checkVideoSource() {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null && (uri.host.contains('youtube.com') || uri.host.contains('youtu.be'))) {
      _isYoutube = true;
      String? videoId;
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.path.contains('embed/')) {
        videoId = uri.pathSegments.last;
      } else {
        videoId = uri.queryParameters['v'];
      }

      if (videoId != null) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
            loop: false,
          ),
        );
      } else {
        _isYoutube = false;
      }
    }
  }

  @override
  void dispose() {
    if (_isYoutube) {
      _controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: YoutubePlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
        ),
      );
    }

    // Fallback for non-YouTube videos (e.g., Vimeo)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_outline, color: Color(0xFF8B5CF6), size: 64),
          const SizedBox(height: 16),
          const Text(
            'External Video Content',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(widget.videoUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
