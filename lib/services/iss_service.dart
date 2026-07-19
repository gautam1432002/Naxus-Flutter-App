import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/iss_model.dart';

class IssService {
  Future<IssModel> fetchIssPosition() async {
    const String url = 'https://api.wheretheiss.at/v1/satellites/25544';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IssModel.fromJson(data);
      } else {
        throw Exception('Failed to load ISS position: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }
}
