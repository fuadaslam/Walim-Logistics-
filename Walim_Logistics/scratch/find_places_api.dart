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
    '/geofences',
    '/markers',
    '/pois',
    '/zones',
    '/places',
    '/locations',
    '/areas',
    '/regions',
    '/points',
    '/geozones',
    '/geofencing/geofences',
    '/geofencing/markers',
    '/geofencing/pois',
    '/geofencing/zones',
    '/geofencing/places',
    '/api/geofences',
    '/api/markers',
    '/api/pois',
    '/v1/geofences',
    '/v1/markers',
    '/v1/pois',
    '/v1/zones',
    '/v1/places',
    '/get_geofences',
    '/get_markers',
    '/get_pois',
    '/get_zones',
    '/get_places',
    '/pois/list',
    '/geofences/list',
    '/zones/list',
    '/markers/list',
    '/pois/all',
    '/geofences/all',
    '/zones/all',
    '/markers/all',
    '/devices/geofences',
    '/devices/markers',
    '/devices/pois',
    '/devices/zones',
    '/devices/places',
    '/accounts/geofences',
    '/accounts/markers',
    '/accounts/pois',
    '/accounts/zones',
    '/accounts/places',
    '/me/geofences',
    '/me/markers',
    '/me/pois',
    '/me/zones',
    '/me/places',
    '/places/markers',
    '/places/zones',
    '/places/pois',
    '/geofence',
    '/marker',
    '/poi',
    '/zone',
    '/place',
    '/resources/geofences',
    '/resources/markers',
    '/resources/pois',
    '/resources/zones',
    '/resources/places',
  ];

  for (var endpoint in endpoints) {
    final url = Uri.parse('$baseUrl$endpoint');
    print('Checking $url...');
    try {
      final res = await http.get(url, headers: headers);
      if (res.statusCode != 404) {
        print('--- FOUND! $endpoint ---');
        print('Status: ${res.statusCode}');
        print('Body: ${res.body.length > 1000 ? res.body.substring(0, 1000) : res.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
