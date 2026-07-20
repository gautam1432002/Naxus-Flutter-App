class LocationModel {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
