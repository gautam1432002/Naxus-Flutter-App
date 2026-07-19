class IssModel {
  final double latitude;
  final double longitude;
  final double altitude;
  final double velocity;
  final int timestamp;

  IssModel({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.velocity,
    required this.timestamp,
  });

  factory IssModel.fromJson(Map<String, dynamic> json) {
    return IssModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      velocity: (json['velocity'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
    );
  }
}
