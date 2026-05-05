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
        .maybeSingle();

    if (response != null) {
      await _supabase
          .from('attendance')
          .update({
            'check_out_time': DateTime.now().toIso8601String(),
            'check_out_lat': lat,
            'check_out_long': long,
          })
          .eq('id', response['id']);
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

  Future<List<String>> getTodayCheckInPeriods(String profileId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();
      final response = await _supabase
          .from('attendance')
          .select('check_in_time')
          .eq('profile_id', profileId)
          .gte('check_in_time', startOfDay);

      final Set<String> periods = {};
      for (final row in response as List) {
        if (row['check_in_time'] != null) {
          final time = DateTime.parse(
            row['check_in_time'].toString(),
          ).toLocal();
          periods.add(getShiftPeriod(time));
        }
      }
      return periods.toList();
    } catch (e) {
      return [];
    }
  }

  String getShiftPeriod(DateTime time) {
    final hour = time.hour;
    if (hour >= 4 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 22) return 'Evening';
    return 'Night';
  }
}
