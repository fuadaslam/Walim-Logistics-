import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://yotkztmstrhrdqffcciz.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdGt6dG1zdHJocmRxZmZjY2l6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NDIwODAsImV4cCI6MjA5MjUxODA4MH0.cuHo4bPYBVS9IH2vpWYWcKeA4r2sBhwnzeVY6nneh_8',
  );

  try {
    final res = await client.from('zones').select();
    print('Zones count: ${res.length}');
    if (res.isNotEmpty) {
      print('First zone: ${res.first}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
