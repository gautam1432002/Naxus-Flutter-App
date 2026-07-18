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
}
