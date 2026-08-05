import '../models/weather_model.dart';
import '../models/data_result.dart';
import 'api_client.dart';

class WeatherService {
  final ApiClient _apiClient = ApiClient();

  static final Map<String, WeatherModel> _memoryCache = {};

  static WeatherModel? getCachedWeather(String locationName) {
    return _memoryCache[locationName];
  }

  Future<DataResult<WeatherModel>> fetchWeather(double latitude, double longitude, {String? locationName}) async {
    final url = 'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day&hourly=temperature_2m,weather_code,is_day&daily=uv_index_max,sunrise,sunset,temperature_2m_max,temperature_2m_min&timezone=auto';

    final response = await _apiClient.getJson(url, cacheKey: 'weather_${latitude}_$longitude');
    
    final weatherModel = WeatherModel.fromJson(response.data);
    
    if (locationName != null) {
      _memoryCache[locationName] = weatherModel;
    }

    return DataResult(
      weatherModel,
      isOffline: response.isStale,
    );
  }
}
