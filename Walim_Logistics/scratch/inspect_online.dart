import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '57A645391187945A971B78D029383038';
  const baseUrl = 'https://beta-api-iot.alrakeen.sa/api';
  
  final headers = {
    'Accept': 'application/json',
    'X-API-KEY': apiKey,
  };

  print('Fetching all fields for a device...');
  try {
    final res = await http.get(Uri.parse('$baseUrl/devices/locations'), headers: headers);
    print('Response status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = data['data'] as List;
      print('Items found: ${items.length}');
      
      bool found = false;
      for (var item in items) {
        final keys = item.keys.where((k) => k.contains('marker') || k.contains('zone')).toList();
        if (keys.isNotEmpty) {
          print('FOUND DEVICE WITH SPECIAL KEYS: ${item['name']}');
          print('Keys: $keys');
          print(JsonEncoder.withIndent('  ').convert(item));
          found = true;
          break;
        }
      }
      
      if (!found) {
        print('No devices found with marker/zone keys in the flat response.');
        // Check if there is an 'attributes' or 'others' field
        if (items.isNotEmpty && (items.first.containsKey('attributes') || items.first.containsKey('others'))) {
           print('Checking nested attributes...');
           // ...
        }
      }
    } else {
      print('Error body: ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
