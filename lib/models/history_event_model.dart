class HistoryEventModel {
  final String year;
  final String text;
  final String? pageThumbnailUrl;

  HistoryEventModel({
    required this.year,
    required this.text,
    this.pageThumbnailUrl,
  });

  factory HistoryEventModel.fromJson(Map<String, dynamic> json) {
    String parsedYear = '';
    if (json['year'] != null) {
      parsedYear = json['year'].toString();
    }

    String? thumbUrl;
    if (json['pages'] != null && json['pages'] is List && json['pages'].isNotEmpty) {
      final firstPage = json['pages'][0];
      if (firstPage['thumbnail'] != null && firstPage['thumbnail']['source'] != null) {
        thumbUrl = firstPage['thumbnail']['source'];
      }
    }

    return HistoryEventModel(
      year: parsedYear,
      text: json['text'] ?? '',
      pageThumbnailUrl: thumbUrl,
    );
  }
}
