import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  const baseUrl = 'https://beta-api-iot.alrakeen.sa/api';
  
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  print('Checking all fields of moving devices...');
  try {
    final res = await http.get(Uri.parse('$baseUrl/devices/locations'), headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = data['data'] as List;
      for (var item in items) {
        if (item['status'] == 'moving') {
          print(item.keys.toList());
          // Check for any field containing 'geo' or 'zone' or 'store'
          item.forEach((k, v) {
            if (k.contains('geo') || k.contains('zone') || k.contains('store')) {
              print('MATCH: $k = $v');
            }
          });
          break;
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
