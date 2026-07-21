import '../models/iss_model.dart';
import 'api_client.dart';

class IssService {
  final ApiClient _apiClient = ApiClient();

  Future<IssModel> fetchIssPosition() async {
    const String primaryUrl = 'https://api.wheretheiss.at/v1/satellites/25544';
    const String fallbackUrl = 'http://api.open-notify.org/iss-now.json';

    try {
      final response = await _apiClient.getJson(primaryUrl, timeout: const Duration(seconds: 4));
      return IssModel.fromJson(response.data);
    } catch (_) {
      final fallbackResponse = await _apiClient.getJson(fallbackUrl, timeout: const Duration(seconds: 4));
      final pos = fallbackResponse.data['iss_position'];
      return IssModel(
        latitude: double.parse(pos['latitude']),
        longitude: double.parse(pos['longitude']),
        altitude: 0.0,
        velocity: 0.0,
        timestamp: fallbackResponse.data['timestamp'],
      );
    }
  }
}
