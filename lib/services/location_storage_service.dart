import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';

class LocationStorageService {
  static const String _lastLocationKey = 'last_location';
  static const String _savedLocationsKey = 'saved_locations';

  Future<void> saveLastLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationKey, jsonEncode(location.toJson()));
  }

  Future<LocationModel?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_lastLocationKey);
    if (data != null) {
      return LocationModel.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<void> addSavedLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getSavedLocations();
    
    // Remove if already exists (match name and country)
    locations.removeWhere((loc) => loc.name == location.name && loc.country == location.country);
    
    // Add to front
    locations.insert(0, location);
    
    // Limit to 5
    if (locations.length > 5) {
      locations.removeLast();
    }
    
    // Save
    final jsonList = locations.map((loc) => loc.toJson()).toList();
    await prefs.setString(_savedLocationsKey, jsonEncode(jsonList));
  }

  Future<List<LocationModel>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_savedLocationsKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((json) => LocationModel.fromJson(json)).toList();
    }
    return [];
  }
}
