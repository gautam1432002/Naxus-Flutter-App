import '../models/weather_model.dart';
import 'api_client.dart';

class WeatherService {
  final ApiClient _apiClient = ApiClient();

  Future<WeatherModel> fetchWeather(double latitude, double longitude) async {
    final url = 'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=uv_index_max,sunrise,sunset&timezone=auto';

    final response = await _apiClient.getJson(url, cacheKey: 'weather_${latitude}_$longitude');
    return WeatherModel.fromJson(response.data);
  }
}
