import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  final urls = [
    'https://tracker.alrakeen.sa/api/geofences',
    'https://tracker.alrakeen.sa/api/geozones',
    'https://tracker.alrakeen.sa/api/zones',
  ];

  for (var url in urls) {
    print('Checking $url...');
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      print('Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        print('FOUND!');
      }
    } catch (e) {}
  }
}
