import '../models/iss_model.dart';
import '../models/data_result.dart';
import 'api_client.dart';

class IssService {
  final ApiClient _apiClient = ApiClient();

  Future<DataResult<IssModel>> fetchIssPosition() async {
    const String primaryUrl = 'https://api.wheretheiss.at/v1/satellites/25544';
    final response = await _apiClient.getJson(primaryUrl, timeout: const Duration(seconds: 15), cacheKey: 'iss_current');
    return DataResult(
      IssModel.fromJson(response.data),
      isOffline: response.isStale,
    );
  }

  Future<DataResult<List<IssModel>>> fetchInitialPositions() async {
    final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final past = now - 10;
    final String url = 'https://api.wheretheiss.at/v1/satellites/25544/positions?timestamps=$past,$now';
    final response = await _apiClient.getJson(url, timeout: const Duration(seconds: 15), cacheKey: 'iss_initial_positions');
    final List<dynamic> data = response.data;
    return DataResult(
      data.map((json) => IssModel.fromJson(json)).toList(),
      isOffline: response.isStale,
    );
  }
}
