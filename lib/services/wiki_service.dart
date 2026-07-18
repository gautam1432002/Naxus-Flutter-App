import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/history_event_model.dart';

class WikiService {
  Future<List<HistoryEventModel>> fetchOnThisDayEvents() async {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final url = 'https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/$month/$day';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final eventsJson = data['events'] as List?;
        if (eventsJson == null) return [];

        return eventsJson.map((e) => HistoryEventModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load events: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }
}
