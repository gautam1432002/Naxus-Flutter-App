import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_model.dart';

class AirQualityService {
  Future<AirQualityModel> fetchAirQuality(double latitude, double longitude) async {
    final String url = 'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$latitude&longitude=$longitude&current=european_aqi,pm2_5,pm10';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AirQualityModel.fromJson(data);
      } else {
        throw Exception('Failed to load air quality: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }
}
