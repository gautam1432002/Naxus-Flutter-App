import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/apod_model.dart';
import 'api_client.dart';

class NasaService {
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';
  final ApiClient _apiClient = ApiClient();

  Future<ApodModel> fetchApod({String? date}) async {
    final apiKey = dotenv.env['NASA_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'PASTE_YOUR_KEY_HERE') {
      throw Exception('NASA_API_KEY is missing or invalid in .env file.');
    }

    String url = '$_baseUrl?api_key=$apiKey';
    if (date != null) {
      url += '&date=$date';
    }
    
    final response = await _apiClient.getJson(url, cacheKey: date != null ? 'apod_$date' : 'apod_today');
    return ApodModel.fromJson(response.data);
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

    final response = await _apiClient.getJson(
      '$_baseUrl?api_key=$apiKey&start_date=$startStr&end_date=$endStr',
      cacheKey: 'apod_range_${startStr}_$endStr',
    );
    
    final List<dynamic> data = response.data;
    final list = data.map((json) => ApodModel.fromJson(json as Map<String, dynamic>)).toList();
    return list.reversed.toList();
  }
}
