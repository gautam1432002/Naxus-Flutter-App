import '../models/iss_model.dart';
import 'api_client.dart';

class IssService {
  final ApiClient _apiClient = ApiClient();

  Future<IssModel> fetchIssPosition() async {
    const String primaryUrl = 'https://api.wheretheiss.at/v1/satellites/25544';

    final response = await _apiClient.getJson(primaryUrl, timeout: const Duration(seconds: 15));
    return IssModel.fromJson(response.data);
  }
}
