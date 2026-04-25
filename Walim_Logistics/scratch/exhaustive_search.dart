import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  const baseUrl = 'https://beta-api-iot.alrakeen.sa/api';
  
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  print('Checking device keys...');
  try {
    final res = await http.get(Uri.parse('$baseUrl/devices/locations'), headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = data['data'] as List;
      if (items.isNotEmpty) {
        print('Keys in device object: ${items.first.keys.toList()}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  // Try to find ANY endpoint that works
  final prefixes = ['', '/v1', '/v2', '/monitoring', '/fleet', '/geofencing'];
  final suffixes = ['/geofences', '/zones', '/areas', '/pois', '/stores'];
  
  for (var p in prefixes) {
    for (var s in suffixes) {
      final url = '$baseUrl$p$s';
      print('Testing $url...');
      try {
        final res = await http.get(Uri.parse(url), headers: headers);
        if (res.statusCode == 200) {
          print('!!! FOUND: $url');
          return;
        }
      } catch (e) {}
    }
  }
}
