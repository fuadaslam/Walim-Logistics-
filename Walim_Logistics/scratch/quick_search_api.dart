
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
    '/positions',
    '/latest',
    '/tracks',
    '/events',
    '/reports',
    '/status',
    '/online',
    '/users/me',
    '/account',
    '/me',
  ];

  for (var endpoint in endpoints) {
    print('Checking $endpoint...');
    try {
      final res = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers).timeout(Duration(seconds: 5));
      print('  -> Result: ${res.statusCode}');
      if (res.statusCode == 200) {
         print('  !!! FOUND DATA ON $endpoint !!!');
      }
    } catch (e) {
      print('  -> Error: Timeout or Fail');
    }
  }
}
