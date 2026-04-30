import 'package:supabase_flutter/supabase_flutter.dart';

class HRRepository {
  final SupabaseClient _supabase;

  HRRepository(this._supabase);

  Future<Map<String, dynamic>> getHRStats() async {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));

    final results = await Future.wait([
      _supabase.from('profiles').select('id'),
      _supabase.from('leave_requests').select('id').eq('status', 'Pending'),
      _supabase
          .from('documents')
          .select('id')
          .lte('expiry_date', thirtyDaysLater.toIso8601String().split('T')[0])
          .gte('expiry_date', now.toIso8601String().split('T')[0]),
    ]);

    return {
      'totalStaff': (results[0] as List).length,
      'pendingLeaves': (results[1] as List).length,
      'complianceAlerts': (results[2] as List).length,
    };
  }

  Future<List<Map<String, dynamic>>> getComplianceAlerts() async {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    return await _supabase
        .from('documents')
        .select('*, profiles(full_name)')
        .lte('expiry_date', thirtyDaysLater.toIso8601String().split('T')[0])
        .gte('expiry_date', now.toIso8601String().split('T')[0])
        .order('expiry_date', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getAllLeaveRequests({int limit = 20}) async {
    return await _supabase
        .from('leave_requests')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<List<Map<String, dynamic>>> getLeaveRequestsForProfile(
    String profileId, {
    int limit = 10,
  }) async {
    return await _supabase
        .from('leave_requests')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<void> submitLeaveRequest({
    required String profileId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    await _supabase.from('leave_requests').insert({
      'profile_id': profileId,
      'type': type,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'reason': reason,
      'status': 'Pending',
    });
  }

  Future<void> reviewLeaveRequest({
    required String requestId,
    required String status,
    required String reviewedBy,
  }) async {
    await _supabase.from('leave_requests').update({
      'status': status,
      'reviewed_by': reviewedBy,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 5}) async {
    return await _supabase
        .from('leave_requests')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    return await _supabase
        .from('profiles')
        .select('*, roles(name)')
        .order('full_name', ascending: true);
  }
}
