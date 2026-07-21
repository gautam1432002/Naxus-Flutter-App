import '../models/history_event_model.dart';
import 'api_client.dart';

class WikiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<HistoryEventModel>> fetchOnThisDayEvents() async {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final url = 'https://en.wikipedia.org/api/rest_v1/feed/onthisday/events/$month/$day';

    final response = await _apiClient.getJson(
      url, 
      cacheKey: 'wiki_events_${month}_$day',
      headers: {'Accept': 'application/json'},
    );
    
    final eventsJson = response.data['events'] as List?;
    if (eventsJson == null) return [];

    return eventsJson.map((e) => HistoryEventModel.fromJson(e)).toList();
  }
}
