import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'https://yotkztmstrhrdqffcciz.supabase.co/rest/v1/zones';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdGt6dG1zdHJocmRxZmZjY2l6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NDIwODAsImV4cCI6MjA5MjUxODA4MH0.cuHo4bPYBVS9IH2vpWYWcKeA4r2sBhwnzeVY6nneh_8';
  
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
  };

  print('Fetching data from Supabase zones table...');
  try {
    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      print('Total zones: ${data.length}');
      if (data.isNotEmpty) {
        print('Sample zone: ${data.first}');
      }
    } else {
      print('Error: ${res.statusCode}');
      print(res.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
