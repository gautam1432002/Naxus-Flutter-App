import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  final globalHeaders = {'User-Agent': 'NexusApp/1.0', 'Accept': 'application/json'};
  
  // Test NASA
  print("Testing NASA API...");
  try {
    final apiKey = 'fIwyNaxYxa7zWtzQCbNj3u5jmpoNME0YJrdkD4g4';
    final res = await http.get(Uri.parse('https://api.nasa.gov/planetary/apod?api_key=$apiKey'), headers: globalHeaders);
    print("NASA status: ${res.statusCode}");
    if (res.statusCode != 200) print("NASA error: ${res.body}");
  } catch(e) {
    print("NASA threw: $e");
  }

  // Test Weather (Open-Meteo)
  print("Testing Weather API...");
  try {
    final res = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current_weather=true'), headers: globalHeaders);
    print("Weather status: ${res.statusCode}");
    if (res.statusCode != 200) print("Weather error: ${res.body}");
  } catch(e) {
    print("Weather threw: $e");
  }
}
