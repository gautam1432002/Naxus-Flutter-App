import 'package:flutter/material.dart';

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final bool isDay;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.isDay,
  });

  String get conditionLabel {
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
}

class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final double uvIndexMax;
  final String sunrise;
  final String sunset;
  final bool isDay;
  final double dailyMaxTemp;
  final double dailyMinTemp;
  final List<HourlyWeather> hourlyForecast;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.uvIndexMax,
    required this.sunrise,
    required this.sunset,
    required this.isDay,
    required this.dailyMaxTemp,
    required this.dailyMinTemp,
    required this.hourlyForecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    final daily = json['daily'] ?? {};
    final hourly = json['hourly'] ?? {};
    
    // daily returns lists of values, we want the first element (today)
    final uvIndexList = daily['uv_index_max'] as List?;
    final sunriseList = daily['sunrise'] as List?;
    final sunsetList = daily['sunset'] as List?;
    final maxTempList = daily['temperature_2m_max'] as List?;
    final minTempList = daily['temperature_2m_min'] as List?;

    List<HourlyWeather> parsedHourly = [];
    if (hourly['time'] != null) {
      final times = hourly['time'] as List;
      final temps = hourly['temperature_2m'] as List;
      final codes = hourly['weather_code'] as List;
      final isDays = hourly['is_day'] as List;

      for (int i = 0; i < times.length; i++) {
        parsedHourly.add(HourlyWeather(
          time: DateTime.parse(times[i]),
          temperature: (temps[i] as num).toDouble(),
          weatherCode: (codes[i] as num).toInt(),
          isDay: (isDays[i] as num).toInt() == 1,
        ));
      }
    }

    return WeatherModel(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      uvIndexMax: (uvIndexList != null && uvIndexList.isNotEmpty) ? (uvIndexList[0] as num).toDouble() : 0.0,
      sunrise: (sunriseList != null && sunriseList.isNotEmpty) ? sunriseList[0].toString() : '',
      sunset: (sunsetList != null && sunsetList.isNotEmpty) ? sunsetList[0].toString() : '',
      isDay: (current['is_day'] as num?)?.toInt() == 1,
      dailyMaxTemp: (maxTempList != null && maxTempList.isNotEmpty) ? (maxTempList[0] as num).toDouble() : 0.0,
      dailyMinTemp: (minTempList != null && minTempList.isNotEmpty) ? (minTempList[0] as num).toDouble() : 0.0,
      hourlyForecast: parsedHourly,
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
