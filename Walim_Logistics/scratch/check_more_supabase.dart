import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdGt6dG1zdHJocmRxZmZjY2l6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NDIwODAsImV4cCI6MjA5MjUxODA4MH0.cuHo4bPYBVS9IH2vpWYWcKeA4r2sBhwnzeVY6nneh_8';
  
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
  };

  final tables = ['stores', 'geofences', 'areas', 'locations', 'points_of_interest'];
  
  for (var table in tables) {
    print('Checking Supabase table: $table...');
    try {
      final res = await http.get(Uri.parse('https://yotkztmstrhrdqffcciz.supabase.co/rest/v1/$table'), headers: headers);
      print('Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        print('FOUND! ${res.body}');
      }
    } catch (e) {}
  }
}
