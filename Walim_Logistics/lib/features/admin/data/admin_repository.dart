import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();

    final riderRole = await _supabase.from('roles').select('id').eq('name', 'Rider').single();
    final riderRoleId = riderRole['id'];

    final results = await Future.wait<dynamic>([
      _supabase.from('profiles').select('id').eq('role_id', riderRoleId).ilike('status', 'active'),
      _supabase.from('vehicles').select('status'),
      _supabase.from('cod_reconciliation').select('collected_amount').ilike('status', 'pending'),
      _supabase
          .from('attendance')
          .select('id')
          .filter('check_out_time', 'is', null)
          .gte('check_in_time', today),
      _supabase.from('profiles').select('id').or('status.ilike.on leave,status.ilike.on_leave,status.ilike.leave').count(CountOption.exact),
      _supabase.from('leave_requests').select('id').ilike('status', 'pending').count(CountOption.exact),
    ]);

    final activeRiders = (results[0] as List).length;

    final vehicles = results[1] as List;
    final operationalVehicles = vehicles
        .where((v) => v['status'] == 'available' || v['status'] == 'in_use')
        .length;
    final fleetHealth = vehicles.isNotEmpty
        ? (operationalVehicles / vehicles.length * 100).toInt()
        : 0;

    final codRows = results[2] as List;
    final pendingCod = codRows.fold<double>(
      0.0,
      (sum, row) => sum + ((row['collected_amount'] as num?)?.toDouble() ?? 0.0),
    );

    final liveOrders = (results[3] as List).length;
    final onLeave = results[4].count ?? 0;
    final pendingRequests = results[5].count ?? 0;

    return {
      'activeRiders': activeRiders,
      'fleetHealth': fleetHealth,
      'pendingCod': pendingCod,
      'liveOrders': liveOrders,
      'onLeave': onLeave,
      'pendingRequests': pendingRequests,
    };
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50}) async {
    final response = await _supabase
        .from('audit_logs')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> logAction({
    required String userId,
    required String action,
    required String entityType,
    Map<String, dynamic>? metadata,
  }) async {
    await _supabase.from('audit_logs').insert({
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'metadata': metadata,
    });
  }
}
