import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  const baseUrl = 'https://beta-api-iot.alrakeen.sa/api';
  
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  final endpoints = [
    '/geozones',
    '/pois',
    '/poi',
    '/geofencing',
    '/v1/geofence',
    '/geofences/v1',
    '/zones/v1',
    '/user/geofences',
  ];

  for (var endpoint in endpoints) {
    print('Checking $endpoint...');
    try {
      final res = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
      if (res.statusCode != 404) {
        print('Status: ${res.statusCode}');
        if (res.statusCode == 200) {
          print('FOUND!');
          print(res.body.substring(0, 500));
        }
      }
    } catch (e) {
      // ignore
    }
  }
}
