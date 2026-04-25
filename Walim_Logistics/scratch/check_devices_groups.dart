import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  final urls = [
    'https://beta-api-iot.alrakeen.sa/api/devices',
    'https://beta-api-iot.alrakeen.sa/api/v1/devices',
    'https://beta-api-iot.alrakeen.sa/api/groups',
    'https://beta-api-iot.alrakeen.sa/api/v1/groups',
  ];

  for (var url in urls) {
    print('Checking $url...');
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      print('Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        print(res.body.length > 1000 ? res.body.substring(0, 1000) : res.body);
      }
    } catch (e) {}
  }
}
