import '../models/air_quality_model.dart';
import 'api_client.dart';

class AirQualityService {
  final ApiClient _apiClient = ApiClient();

  Future<AirQualityModel> fetchAirQuality(double latitude, double longitude) async {
    final String url = 'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$latitude&longitude=$longitude&current=european_aqi,pm2_5,pm10';
    
    final response = await _apiClient.getJson(url, cacheKey: 'aqi_${latitude}_$longitude');
    return AirQualityModel.fromJson(response.data);
  }
}
