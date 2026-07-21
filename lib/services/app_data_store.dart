import 'dart:async';

import '../models/apod_model.dart';
import '../models/iss_model.dart';
import '../models/air_quality_model.dart';
import '../models/weather_model.dart';
import '../models/history_event_model.dart';

import 'nasa_service.dart';
import 'iss_service.dart';
import 'air_quality_service.dart';
import 'weather_service.dart';
import 'wiki_service.dart';
import 'location_storage_service.dart';

class AppDataStore {
  // Singleton instance
  static final AppDataStore _instance = AppDataStore._internal();
  factory AppDataStore() => _instance;
  AppDataStore._internal();

  // Cached data fields
  ApodModel? todayApod;
  IssModel? issPosition;
  AirQualityModel? airQuality;
  WeatherModel? weather;
  List<HistoryEventModel>? historyEvents;

  bool isPrefetching = false;

  Future<void> prefetchAll() async {
    if (isPrefetching) return;
    isPrefetching = true;

    final nasaService = NasaService();
    final issService = IssService();
    final wikiService = WikiService();
    final locationStorageService = LocationStorageService();
    final airQualityService = AirQualityService();
    final weatherService = WeatherService();

    // 1. Fetch Location independent data
    final Future<void> fetchNasa = () async {
      try {
        todayApod = await nasaService.fetchApod();
      } catch (e) {
        // Silently ignore prefetch failures
      }
    }();

    final Future<void> fetchIss = () async {
      try {
        issPosition = await issService.fetchIssPosition();
      } catch (e) {
        // Silently ignore prefetch failures
      }
    }();

    final Future<void> fetchWiki = () async {
      try {
        historyEvents = await wikiService.fetchOnThisDayEvents();
      } catch (e) {
        // Silently ignore prefetch failures
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
          weather = results[0] as WeatherModel;
          airQuality = results[1] as AirQualityModel;
        }
      } catch (e) {
        // Silently ignore prefetch failures
      }
    }();

    await Future.wait([
      fetchNasa,
      fetchIss,
      fetchWiki,
      fetchLocationData,
    ]);

    isPrefetching = false;
  }
}
