import 'package:supabase_flutter/supabase_flutter.dart';

class HRRepository {
  final SupabaseClient _supabase;

  HRRepository(this._supabase);

  // Leave Management
  Future<void> requestLeave({
    required String profileId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    await _supabase.from('profiles').update({
      'status': 'on_leave',
    }).eq('id', profileId);
    
    // In a real app, you'd have a separate leave_requests table
    // For now, we'll simulate this with a log or a specific status update
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    return await _supabase
        .from('profiles')
        .select()
        .eq('status', 'on_leave');
  }

  // Housing (Sakan) Management
  Future<void> assignHousing({
    required String profileId,
    required String housingName,
    required String roomNumber,
  }) async {
    // Logic to assign laborer accommodation
    // This could update a 'housing_assignments' table
  }
}
