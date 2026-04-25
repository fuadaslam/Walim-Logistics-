import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository(this._supabase);

  Future<void> checkIn({
    required String profileId,
    required double lat,
    required double long,
    required bool isValid,
  }) async {
    await _supabase.from('attendance').insert({
      'profile_id': profileId,
      'check_in_lat': lat,
      'check_in_long': long,
      'is_geofenced_valid': isValid,
      'attendance_type': 'shift',
    });
  }

  Future<void> checkOut({
    required String profileId,
    required double lat,
    required double long,
  }) async {
    // Find the latest active check-in and update it
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('profile_id', profileId)
        .filter('check_out_time', 'is', null)
        .order('check_in_time', ascending: false)
        .limit(1)
        .single();

    if (response != null) {
      await _supabase.from('attendance').update({
        'check_out_time': DateTime.now().toIso8601String(),
        'check_out_lat': lat,
        'check_out_long': long,
      }).eq('id', response['id']);
    }
  }

  Future<Map<String, dynamic>?> getActiveShift(String profileId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('profile_id', profileId)
          .filter('check_out_time', 'is', null)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }
}
