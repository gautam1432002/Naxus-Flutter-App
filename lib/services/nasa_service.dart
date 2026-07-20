import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/apod_model.dart';

class NasaService {
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';

  Future<ApodModel> fetchApod({String? date}) async {
    final apiKey = dotenv.env['NASA_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'PASTE_YOUR_KEY_HERE') {
      throw Exception('NASA_API_KEY is missing or invalid in .env file.');
    }

    try {
      String url = '$_baseUrl?api_key=$apiKey';
      if (date != null) {
        url += '&date=$date';
      }
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApodModel.fromJson(data);
      } else {
        throw Exception('Failed to load APOD: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }

  Future<List<ApodModel>> fetchApodRange() async {
    final apiKey = dotenv.env['NASA_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'PASTE_YOUR_KEY_HERE') {
      throw Exception('NASA_API_KEY is missing or invalid in .env file.');
    }

    final today = DateTime.now();
    final endDate = today.subtract(const Duration(days: 1));
    final startDate = today.subtract(const Duration(days: 3));

    String format(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    final startStr = format(startDate);
    final endStr = format(endDate);

    try {
      final response = await http.get(Uri.parse('$_baseUrl?api_key=$apiKey&start_date=$startStr&end_date=$endStr'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((json) => ApodModel.fromJson(json as Map<String, dynamic>)).toList();
        return list.reversed.toList();
      } else {
        throw Exception('Failed to load APOD range: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }
}
