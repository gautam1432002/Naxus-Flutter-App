import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  Future<WeatherModel> fetchWeather(double latitude, double longitude) async {
    final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=uv_index_max,sunrise,sunset&timezone=auto');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        throw Exception('Failed to load weather: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }
}
