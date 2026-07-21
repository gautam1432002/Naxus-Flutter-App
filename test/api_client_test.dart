import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ApiClient caches data on success and returns stale data on failure', () async {
    // 1. Manually seed the SharedPreferences mock with "cached" data
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'timestamp': timestamp,
      'data': '{"id": 99, "title": "Stale Data Fallback"}',
    };
    
    SharedPreferences.setMockInitialValues({
      'flutter.test_key': '{"timestamp": $timestamp, "data": "{\\"id\\": 99, \\"title\\": \\"Stale Data Fallback\\"}"}'
    });
    
    final client = ApiClient();
    
    // 2. Simulated failure request.
    // Note: TestWidgetsFlutterBinding forces all network calls to return HTTP 400.
    // This perfectly triggers our API Client's failure handler!
    print('Simulating a network failure...');
    final staleResponse = await client.getJson(
      'https://this-domain-is-definitely-broken-and-fake.com/api', 
      cacheKey: 'test_key', 
    );
    
    expect(staleResponse.isStale, true);
    expect(staleResponse.data['id'], 99); 
    expect(staleResponse.data['title'], "Stale Data Fallback"); 
    print('Stale fallback successful! Age in minutes: ${staleResponse.staleAgeMinutes}');
  });
}
