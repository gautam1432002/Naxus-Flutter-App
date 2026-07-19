class AirQualityModel {
  final double europeanAqi;
  final double pm2_5;
  final double pm10;

  AirQualityModel({
    required this.europeanAqi,
    required this.pm2_5,
    required this.pm10,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    
    return AirQualityModel(
      europeanAqi: (current['european_aqi'] as num?)?.toDouble() ?? 0.0,
      pm2_5: (current['pm2_5'] as num?)?.toDouble() ?? 0.0,
      pm10: (current['pm10'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
