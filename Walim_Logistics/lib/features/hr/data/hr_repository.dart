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
    final response = await _supabase.from('profiles').select('*, roles(name)');
    return (response as List).map((p) {
      final profile = p as Map<String, dynamic>;
      final roleData = profile['roles'];
      String roleName = 'Staff';
      if (roleData is Map) {
        roleName = roleData['name'] ?? 'Staff';
      } else if (roleData is List && roleData.isNotEmpty) {
        roleName = roleData[0]['name'] ?? 'Staff';
      }
      return {
        ...profile,
        'role': roleName,
      };
    }).toList().cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getProfileStats(String profileId) async {
    final results = await Future.wait([
      _supabase.from('attendance').select('id').eq('profile_id', profileId).eq('attendance_type', 'shift'),
      _supabase.from('leave_requests').select('id').eq('profile_id', profileId).eq('status', 'pending'),
      _supabase.from('incidents').select('id').eq('reported_by', profileId).eq('status', 'pending'),
      _supabase.from('leave_requests').select('id').eq('profile_id', profileId).eq('status', 'Approved'),
    ]);

    final workingDays = (results[0] as List).length;
    final pendingLeaves = (results[1] as List).length;
    final pendingIncidents = (results[2] as List).length;
    final approvedLeaves = (results[3] as List).length;

    return {
      'workingDays': workingDays,
      'workingHours': (workingDays * 8).toString(), 
      'leaveDays': approvedLeaves.toString(),
      'pendingRequests': pendingLeaves + pendingIncidents,
    };
  }


  Future<List<Map<String, dynamic>>> getAssetsForProfile(String profileId) async {
    return await _supabase
        .from('assets')
        .select('*, asset_assignments!inner(*)')
        .eq('asset_assignments.profile_id', profileId)
        .filter('asset_assignments.returned_at', 'is', null);
  }

  Future<List<Map<String, dynamic>>> getDocumentsForProfile(String profileId) async {
    return await _supabase
        .from('documents')
        .select('*')
        .eq('profile_id', profileId)
        .order('expiry_date', ascending: true);
  }

  Future<List<Map<String, dynamic>>> getOnboardingStaff() async {
    final staff = await _supabase
        .from('profiles')
        .select('id, full_name, created_at, iqama_number, passport_number, roles(name)')
        .order('created_at', ascending: false)
        .limit(10);

    if ((staff as List).isEmpty) return [];

    return Future.wait((staff as List).map((p) async {
      final id = p['id'] as String;

      final assetAssignments = await _supabase
          .from('asset_assignments')
          .select('id')
          .eq('profile_id', id)
          .filter('returned_at', 'is', null)
          .limit(1);

      final roleData = p['roles'];
      final roleName =
          roleData is Map ? (roleData['name'] as String?) ?? 'Staff' : 'Staff';
      final createdAt = p['created_at'] as String?;
      final hasLegalDocs =
          p['iqama_number'] != null && p['passport_number'] != null;

      return {
        'id': id,
        'name': p['full_name'] ?? 'Unknown',
        'role': roleName,
        'contract': hasLegalDocs ? 'Signed' : 'Pending',
        'training': 0.0,
        'assets':
            (assetAssignments as List).isNotEmpty ? 'Assigned' : 'Pending',
        'startDate':
            createdAt != null ? createdAt.split('T')[0] : 'Unknown',
      };
    }));
  }
}

