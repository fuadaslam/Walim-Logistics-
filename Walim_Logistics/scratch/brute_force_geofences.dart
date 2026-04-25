import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  final base = 'https://beta-api-iot.alrakeen.sa/api';
  final paths = [
    '/geofences',
    '/geozones',
    '/zones',
    '/pois',
    '/geofence',
    '/geozone',
    '/zone',
    '/poi',
    '/v1/geofences',
    '/v1/geozones',
    '/v1/zones',
    '/v1/pois',
    '/geofencing/geofences',
    '/geofencing/geozones',
    '/geofencing/zones',
    '/geofencing/pois',
    '/monitoring/geofences',
    '/monitoring/geozones',
    '/monitoring/zones',
    '/monitoring/pois',
    '/addresses',
    '/locations',
    '/areas',
    '/regions',
    '/sites',
    '/places',
    '/v1/places',
    '/v1/sites',
    '/v1/areas',
    '/v2/geofences',
    '/v2/geozones',
    '/v2/zones',
  ];

  for (var path in paths) {
    final url = '$base$path';
    print('Checking $url...');
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode != 404) {
        print('--- FOUND! Status: ${res.statusCode} ---');
        print(res.body.length > 500 ? res.body.substring(0, 500) : res.body);
        return;
      }
    } catch (e) {
      print('Error checking $url: $e');
    }
  }
}
