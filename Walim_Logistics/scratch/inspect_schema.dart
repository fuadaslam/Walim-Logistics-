
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
    'https://yotkztmstrhrdqffcciz.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdGt6dG1zdHJocmRxZmZjY2l6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NDIwODAsImV4cCI6MjA5MjUxODA4MH0.cuHo4bPYBVS9IH2vpWYWcKeA4r2sBhwnzeVY6nneh_8',
  );

  try {
    final response = await supabase.from('profiles').select().limit(1).single();
    print('Columns in profiles: ${response.keys.toList()}');
    print('Sample profile: $response');
  } catch (e) {
    print('Error: $e');
  }
}
