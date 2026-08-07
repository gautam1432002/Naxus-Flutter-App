import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final globalHeaders = {'User-Agent': 'NexusApp/1.0', 'Accept': 'application/json'};
  
  print("Testing Wiki API...");
  try {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final res = await http.get(Uri.parse('https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/$month/$day'), headers: globalHeaders);
    print("Wiki status: ${res.statusCode}");
    if (res.statusCode != 200) {
       print("Wiki error: ${res.body}");
    }
  } catch(e) {
    print("Wiki threw: $e");
  }

  print("Testing ISS API...");
  try {
    final res = await http.get(Uri.parse('http://api.open-notify.org/iss-now.json'), headers: globalHeaders);
    print("ISS status: ${res.statusCode}");
  } catch(e) {
    print("ISS threw: $e");
  }
}
