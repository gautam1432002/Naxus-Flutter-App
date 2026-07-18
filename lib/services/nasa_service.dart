import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/apod_model.dart';

class NasaService {
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';

  Future<ApodModel> fetchApod() async {
    final apiKey = dotenv.env['NASA_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'PASTE_YOUR_KEY_HERE') {
      throw Exception('NASA_API_KEY is missing or invalid in .env file.');
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl?api_key=$apiKey'));

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
}
