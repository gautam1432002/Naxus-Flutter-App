import '../models/location_model.dart';
import 'api_client.dart';

class GeocodingService {
  final ApiClient _apiClient = ApiClient();

  Future<List<LocationModel>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];
    
    final url = 'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=8';
    
    final response = await _apiClient.getJson(url);
    if (response.data['results'] != null) {
      return (response.data['results'] as List).map((json) => LocationModel.fromJson(json)).toList();
    }
    return [];
  }
}
