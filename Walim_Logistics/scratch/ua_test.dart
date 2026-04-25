import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  const baseUrl = 'https://beta-api-iot.alrakeen.sa/api';
  
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
  };

  print('Checking /geofences with Browser User-Agent...');
  try {
    final res = await http.get(Uri.parse('$baseUrl/geofences'), headers: headers);
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('FOUND!');
    }
  } catch (e) {
    print('Error: $e');
  }
}
