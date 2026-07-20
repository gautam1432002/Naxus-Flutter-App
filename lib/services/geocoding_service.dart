import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class GeocodingService {
  Future<List<LocationModel>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];
    
    final url = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=8');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List).map((json) => LocationModel.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to search cities: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }
}
