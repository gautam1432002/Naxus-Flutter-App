import '../models/iss_model.dart';
import 'api_client.dart';

class IssService {
  final ApiClient _apiClient = ApiClient();

  Future<IssModel> fetchIssPosition() async {
    const String primaryUrl = 'https://api.wheretheiss.at/v1/satellites/25544';
    final response = await _apiClient.getJson(primaryUrl, timeout: const Duration(seconds: 15));
    return IssModel.fromJson(response.data);
  }

  Future<List<IssModel>> fetchInitialPositions() async {
    final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final past = now - 10;
    final String url = 'https://api.wheretheiss.at/v1/satellites/25544/positions?timestamps=$past,$now';
    final response = await _apiClient.getJson(url, timeout: const Duration(seconds: 15));
    final List<dynamic> data = response.data;
    return data.map((json) => IssModel.fromJson(json)).toList();
  }
}
