import 'package:flutter/material.dart';

class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final double uvIndexMax;
  final String sunrise;
  final String sunset;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.uvIndexMax,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    final daily = json['daily'] ?? {};
    
    // daily returns lists of values, we want the first element (today)
    final uvIndexList = daily['uv_index_max'] as List?;
    final sunriseList = daily['sunrise'] as List?;
    final sunsetList = daily['sunset'] as List?;

    return WeatherModel(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      uvIndexMax: (uvIndexList != null && uvIndexList.isNotEmpty) ? (uvIndexList[0] as num).toDouble() : 0.0,
      sunrise: (sunriseList != null && sunriseList.isNotEmpty) ? sunriseList[0].toString() : '',
      sunset: (sunsetList != null && sunsetList.isNotEmpty) ? sunsetList[0].toString() : '',
    );
  }

  String get conditionLabel {
    // WMO Weather interpretation codes
    if (weatherCode == 0) return 'Clear';
    if (weatherCode == 1) return 'Mostly Clear';
    if (weatherCode == 2) return 'Partly Cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode >= 45 && weatherCode <= 48) return 'Fog';
    if (weatherCode >= 51 && weatherCode <= 57) return 'Drizzle';
    if (weatherCode >= 61 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain Showers';
    if (weatherCode >= 85 && weatherCode <= 86) return 'Snow Showers';
    if (weatherCode >= 95 && weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  IconData get conditionIcon {
    if (weatherCode == 0 || weatherCode == 1) return Icons.wb_sunny;
    if (weatherCode == 2) return Icons.cloud_queue;
    if (weatherCode == 3) return Icons.cloud;
    if (weatherCode >= 45 && weatherCode <= 48) return Icons.foggy;
    if (weatherCode >= 51 && weatherCode <= 57) return Icons.grain; // drizzle
    if (weatherCode >= 61 && weatherCode <= 67) return Icons.water_drop; // rain
    if (weatherCode >= 71 && weatherCode <= 77) return Icons.ac_unit; // snow
    if (weatherCode >= 80 && weatherCode <= 82) return Icons.water_drop;
    if (weatherCode >= 85 && weatherCode <= 86) return Icons.ac_unit;
    if (weatherCode >= 95 && weatherCode <= 99) return Icons.thunderstorm;
    return Icons.wb_cloudy; // default
  }
}
