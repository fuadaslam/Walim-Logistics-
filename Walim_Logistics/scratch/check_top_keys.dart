import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  const baseUrl = 'https://beta-api-iot.alrakeen.sa/api';
  
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  print('Checking top-level keys in devices/locations...');
  try {
    final res = await http.get(Uri.parse('$baseUrl/devices/locations'), headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      print('Top-level keys: ${data.keys.toList()}');
      
      if (data.containsKey('meta')) {
        print('Meta keys: ${(data['meta'] as Map).keys.toList()}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  // Try to find if there's a different root for geofences
  // Some APIs use /geofencing/...
  print('\nTrying /geofencing/geozones...');
  try {
    final res = await http.get(Uri.parse('$baseUrl/geofencing/geozones'), headers: headers);
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('FOUND! Body length: ${res.body.length}');
    }
  } catch (e) {}

}
