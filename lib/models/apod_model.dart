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
}
