class ApodModel {
  final String title;
  final String explanation;
  final String url;
  final String date;
  final String mediaType;

  ApodModel({
    required this.title,
    required this.explanation,
    required this.url,
    required this.date,
    required this.mediaType,
  });

  factory ApodModel.fromJson(Map<String, dynamic> json) {
    return ApodModel(
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      url: json['url'] ?? '',
      date: json['date'] ?? '',
      mediaType: json['media_type'] ?? '',
    );
  }

  String get formattedDate {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('-');
      if (parts.length != 3) return date;
      final year = parts[0];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '$day-${months[month - 1]}-$year';
    } catch (e) {
      return date;
    }
  }

  bool get isVideo => mediaType == 'video';

  String? get youtubeThumbnail {
    if (!isVideo) return null;
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.host.contains('youtube.com') || uri.host.contains('youtu.be'))) {
      String? videoId;
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.path.contains('embed/')) {
        videoId = uri.pathSegments.last;
      } else {
        videoId = uri.queryParameters['v'];
      }
      if (videoId != null && videoId.isNotEmpty) {
        final cleanId = videoId.split('?').first;
        return 'https://img.youtube.com/vi/$cleanId/hqdefault.jpg';
      }
    }
    return null;
  }
}
