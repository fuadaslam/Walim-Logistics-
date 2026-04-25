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
    '/zones',
    '/areas',
    '/stores',
    '/locations',
  ];

  for (var endpoint in endpoints) {
    print('Checking $endpoint...');
    try {
      final res = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
      print('Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('Sample data: ${data.toString().substring(0, 200)}...');
      }
    } catch (e) {
      print('Error: $e');
    }
    print('---');
  }
}
