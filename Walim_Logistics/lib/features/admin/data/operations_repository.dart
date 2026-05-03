import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperationsRepository {
  final SupabaseClient _db;
  OperationsRepository(this._db);

  // ── Groups ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final res = await _db
        .from('groups')
        .select('*, platforms(name), zones(name), profiles!supervisor_id(id, full_name)')
        .order('name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? platformId,
    String? zoneId,
    String? supervisorId,
    required String createdBy,
  }) async {
    final res = await _db.from('groups').insert({
      'name': name,
      'platform_id': platformId,
      'zone_id': zoneId,
      'supervisor_id': supervisorId,
      'is_active': true,
    }).select().single();
    return res;
  }

  Future<void> updateGroup({
    required String id,
    required String name,
    String? platformId,
    String? zoneId,
    String? supervisorId,
  }) async {
    await _db.from('groups').update({
      'name': name,
      'platform_id': platformId,
      'zone_id': zoneId,
      'supervisor_id': supervisorId,
    }).eq('id', id);
  }

  Future<void> deleteGroup(String id) async {
    await _db.from('groups').delete().eq('id', id);
  }

  // ── Group Members ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    final res = await _db
        .from('group_members')
        .select('*, profiles!rider_id(id, full_name, iqama_number, phone_number, status)')
        .eq('group_id', groupId)
        .order('added_at');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> addRiderToGroup({
    required String groupId,
    required String riderId,
    required String addedBy,
  }) async {
    await _db.from('group_members').upsert({
      'group_id': groupId,
      'rider_id': riderId,
      'added_by': addedBy,
    });
  }

  Future<void> removeRiderFromGroup({
    required String groupId,
    required String riderId,
  }) async {
    await _db
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('rider_id', riderId);
  }

  // ── Riders & Supervisors ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchRiders() async {
    final res = await _db
        .from('profiles')
        .select('id, full_name, iqama_number, phone_number, status')
        .eq('role_id', await _getRoleId('Rider'))
        .order('full_name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchSupervisors() async {
    final res = await _db
        .from('profiles')
        .select('id, full_name, phone_number')
        .eq('role_id', await _getRoleId('Supervisor'))
        .order('full_name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchPlatforms() async {
    final res = await _db.from('platforms').select('id, name').order('name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchZones() async {
    final res = await _db.from('zones').select('id, name').order('name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> updateProfileStatus(String profileId, String status) async {
    await _db.from('profiles').update({'status': status}).eq('id', profileId);
  }

  Future<void> createProfile({
    required String fullName,
    required String email,
    required String phone,
    required String roleName,
    String? iqamaNumber,
  }) async {
    final roleId = await _getRoleId(roleName);
    // Note: This only creates the profile record. 
    // In a real app, you'd use admin auth to create the user.
    await _db.from('profiles').insert({
      'full_name': fullName,
      'email': email,
      'phone_number': phone,
      'role_id': roleId,
      'iqama_number': iqamaNumber,
      'status': 'Active',
    });
  }

  Future<void> deleteProfile(String profileId) async {
    await _db.from('profiles').delete().eq('id', profileId);
  }

  Future<String> _getRoleId(String roleName) async {
    final res = await _db
        .from('roles')
        .select('id')
        .eq('name', roleName)
        .single();
    return res['id'] as String;
  }

  // ── Shift Plans ───────────────────────────────────────────────────────────

  /// Generates rider_shift_plans for all group members for a given date/shift.
  Future<int> generateShiftPlans({
    required String groupId,
    required String platformId,
    required DateTime shiftDate,
    required DateTime shiftStart,
    required DateTime shiftEnd,
  }) async {
    final members = await fetchGroupMembers(groupId);
    if (members.isEmpty) return 0;

    final dateStr = _fmtDate(shiftDate);

    // Remove existing plans for this group/platform/date to avoid duplicates
    await _db
        .from('rider_shift_plans')
        .delete()
        .eq('group_id', groupId)
        .eq('platform_id', platformId)
        .eq('shift_date', dateStr);

    final rows = members.map((m) => {
          'rider_id': m['rider_id'],
          'platform_id': platformId,
          'group_id': groupId,
          'shift_date': dateStr,
          'shift_start': shiftStart.toIso8601String(),
          'shift_end': shiftEnd.toIso8601String(),
          'import_source': 'ops_planner',
        }).toList();

    await _db.from('rider_shift_plans').insert(rows);
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> fetchShiftPlans({
    required DateTime date,
    String? groupId,
    String? platformId,
  }) async {
    var query = _db
        .from('rider_shift_plans')
        .select('*, profiles!rider_id(id, full_name), groups(name), platforms(name)')
        .eq('shift_date', _fmtDate(date));
    if (groupId != null) query = query.eq('group_id', groupId);
    if (platformId != null) query = query.eq('platform_id', platformId);
    final res = await query.order('shift_start');
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ── Supervisor Schedules ──────────────────────────────────────────────────

  Future<void> assignSupervisor({
    required String supervisorId,
    required String groupId,
    required String platformId,
    required DateTime scheduleDate,
    required DateTime shiftStart,
    required DateTime shiftEnd,
  }) async {
    final dateStr = _fmtDate(scheduleDate);

    // Upsert: one supervisor per group per date
    await _db.from('supervisor_schedules').upsert({
      'supervisor_id': supervisorId,
      'group_id': groupId,
      'platform_id': platformId,
      'schedule_date': dateStr,
      'shift_start': shiftStart.toIso8601String(),
      'shift_end': shiftEnd.toIso8601String(),
    });

    // Also update the group's supervisor_id for quick reference
    await _db
        .from('groups')
        .update({'supervisor_id': supervisorId}).eq('id', groupId);
  }

  Future<List<Map<String, dynamic>>> fetchSchedules(DateTime date) async {
    final res = await _db
        .from('supervisor_schedules')
        .select('*, profiles!supervisor_id(id, full_name), groups(id, name), platforms(name)')
        .eq('schedule_date', _fmtDate(date))
        .order('shift_start');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>?> fetchSupervisorTodaySchedule(
      String supervisorId) async {
    try {
      final res = await _db
          .from('supervisor_schedules')
          .select('*, groups(id, name), platforms(id, name)')
          .eq('supervisor_id', supervisorId)
          .eq('schedule_date', _fmtDate(DateTime.now()))
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Fetch group members with today's attendance status from the latest report.
  Future<List<Map<String, dynamic>>> fetchGroupMembersWithAttendance(
      String groupId) async {
    final members = await fetchGroupMembers(groupId);
    final today = _fmtDate(DateTime.now());

    // Try to get attendance report for today
    final reports = await _db
        .from('attendance_reports')
        .select('id')
        .eq('group_id', groupId)
        .eq('report_date', today)
        .order('created_at', ascending: false)
        .limit(1);

    if ((reports as List).isEmpty) return members;

    final reportId = reports[0]['id'] as String;
    final items = await _db
        .from('attendance_report_items')
        .select('rider_id, attendance_status, absence_reason')
        .eq('attendance_report_id', reportId);

    final statusMap = {
      for (final i in items as List)
        i['rider_id'] as String: i['attendance_status'] as String
    };

    return members.map((m) {
      final riderId = m['rider_id'] as String;
      return {
        ...m,
        'today_status': statusMap[riderId] ?? 'not_marked',
      };
    }).toList();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final operationsRepositoryProvider = Provider<OperationsRepository>(
  (ref) => OperationsRepository(Supabase.instance.client),
);
