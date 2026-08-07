import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/apod_model.dart';
import '../models/iss_model.dart';
import '../models/air_quality_model.dart';
import '../models/weather_model.dart';
import '../models/history_event_model.dart';
import '../models/data_result.dart';

import 'nasa_service.dart';
import 'iss_service.dart';
import 'air_quality_service.dart';
import 'weather_service.dart';
import 'wiki_service.dart';
import 'location_storage_service.dart';

class AppDataStore extends ChangeNotifier {
  // Singleton instance
  static final AppDataStore _instance = AppDataStore._internal();
  factory AppDataStore() => _instance;
  AppDataStore._internal();

  // Cached data fields
  ApodModel? todayApod;
  List<ApodModel>? previousApods;
  IssModel? issPosition;
  AirQualityModel? airQuality;
  WeatherModel? weather;
  List<HistoryEventModel>? historyEvents;

  bool isPrefetching = false;

  Future<void> prefetchAll() async {
    if (isPrefetching) return;
    isPrefetching = true;
    notifyListeners();

    List<String> errors = [];

    final nasaService = NasaService();
    final issService = IssService();
    final wikiService = WikiService();
    final locationStorageService = LocationStorageService();
    final airQualityService = AirQualityService();
    final weatherService = WeatherService();

    // 1. Fetch Location independent data
    final Future<void> fetchNasa = () async {
      try {
        final results = await Future.wait([
          nasaService.fetchApod(),
          nasaService.fetchApodRange(),
        ]);
        todayApod = (results[0] as DataResult<ApodModel>).data;
        previousApods = (results[1] as DataResult<List<ApodModel>>).data;
        notifyListeners();
      } catch (e) {
        errors.add('NASA API: $e');
      }
    }();

    final Future<void> fetchIss = () async {
      try {
        final res = await issService.fetchIssPosition();
        issPosition = res.data;
        notifyListeners();
      } catch (e) {
        errors.add('ISS API: $e');
      }
    }();

    final Future<void> fetchWiki = () async {
      try {
        final res = await wikiService.fetchOnThisDayEvents();
        historyEvents = res.data;
        notifyListeners();
      } catch (e) {
        errors.add('Wiki API: $e');
      }
    }();

    // 2. Fetch Location dependent data (AirPulse)
    final Future<void> fetchLocationData = () async {
      try {
        final lastLoc = await locationStorageService.getLastLocation();
        if (lastLoc != null) {
          final results = await Future.wait([
            weatherService.fetchWeather(lastLoc.latitude, lastLoc.longitude),
            airQualityService.fetchAirQuality(lastLoc.latitude, lastLoc.longitude),
          ]);
          weather = (results[0] as DataResult<WeatherModel>).data;
          airQuality = (results[1] as DataResult<AirQualityModel>).data;
          notifyListeners();
        }
      } catch (e) {
        errors.add('Location Data: $e');
      }
    }();

    await Future.wait([
      fetchNasa,
      fetchIss,
      fetchWiki,
      fetchLocationData,
    ]);

    isPrefetching = false;
    notifyListeners();
    
    if (errors.isNotEmpty) {
      throw Exception('Failed to fetch data: ${errors.join(', ')}');
    }
  }
}
