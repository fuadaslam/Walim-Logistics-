import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  const baseUrl = 'https://beta-api-iot.alrakeen.sa/api';
  
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  print('Checking device details for 26913...');
  try {
    final res = await http.get(Uri.parse('$baseUrl/devices/26913'), headers: headers);
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print(JsonEncoder.withIndent('  ').convert(jsonDecode(res.body)));
    }
  } catch (e) {
    print('Error: $e');
  }
}
