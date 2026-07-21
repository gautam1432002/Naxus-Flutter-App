import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

class ApiResponse {
  final dynamic data;
  final bool isStale;
  final int staleAgeMinutes;

  ApiResponse(this.data, {this.isStale = false, this.staleAgeMinutes = 0});
}

class ApiException implements Exception {
  final String message;
  final String type;

  ApiException(this.message, this.type);

  @override
  String toString() => '$type: $message';
}

class ApiClient {
  final CacheService _cacheService = CacheService();

  Future<ApiResponse> getJson(
    String url, {
    String? cacheKey,
    Duration timeout = const Duration(seconds: 10),
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        if (cacheKey != null) {
          await _cacheService.cacheData(cacheKey, response.body);
        }
        return ApiResponse(jsonDecode(response.body));
      } else {
        return await _handleFailure(
            cacheKey, 'Server error: HTTP ${response.statusCode}', 'ServerError');
      }
    } on TimeoutException {
      return await _handleFailure(cacheKey, 'Request timed out', 'TimeoutException');
    } on SocketException {
      return await _handleFailure(cacheKey, 'No internet connection', 'NetworkException');
    } catch (e) {
      return await _handleFailure(cacheKey, e.toString(), 'UnknownException');
    }
  }

  Future<ApiResponse> _handleFailure(String? cacheKey, String errorMessage, String errorType) async {
    if (cacheKey != null) {
      final cached = await _cacheService.getCachedData(cacheKey);
      if (cached != null) {
        final data = jsonDecode(cached['data'] as String);
        return ApiResponse(
          data,
          isStale: true,
          staleAgeMinutes: cached['ageMinutes'] as int,
        );
      }
    }
    throw ApiException(errorMessage, errorType);
  }
}
