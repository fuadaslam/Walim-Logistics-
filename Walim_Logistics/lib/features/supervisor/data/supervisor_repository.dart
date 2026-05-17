import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorRepository {
  final SupabaseClient _supabase;

  SupervisorRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchGroups({String? supervisorId}) async {
    var query = _supabase
        .from('groups')
        .select('id, name, platform_id')
        .eq('is_active', true);

    if (supervisorId != null) {
      query = query.eq('supervisor_id', supervisorId);
    }

    final res = await query.order('name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchPlatforms() async {
    final res = await _supabase
        .from('platforms')
        .select('id, name')
        .order('name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>?> fetchReport({
    required String supervisorId,
    required DateTime date,
    required String platformId,
    required String groupId,
  }) async {
    final dateStr = _fmtDate(date);
    try {
      final res = await _supabase
          .from('attendance_reports')
          .select()
          .eq('supervisor_id', supervisorId)
          .eq('platform_id', platformId)
          .eq('group_id', groupId)
          .eq('report_date', dateStr)
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createReport({
    required String supervisorId,
    required DateTime date,
    required String platformId,
    required String groupId,
  }) async {
    final res = await _supabase.from('attendance_reports').insert({
      'supervisor_id': supervisorId,
      'platform_id': platformId,
      'group_id': groupId,
      'report_date': _fmtDate(date),
      'status': 'DRAFT',
    }).select().single();
    return res;
  }

  Future<List<Map<String, dynamic>>> fetchPlannedRiders({
    required DateTime date,
    required String platformId,
    required String groupId,
  }) async {
    final res = await _supabase
        .from('rider_shift_plans')
        .select('*, profiles!rider_id(id, full_name, iqama_number)')
        .eq('shift_date', _fmtDate(date))
        .eq('platform_id', platformId)
        .eq('group_id', groupId)
        .order('shift_start');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchReportItems(String reportId) async {
    final res = await _supabase
        .from('attendance_report_items')
        .select('*, profiles!rider_id(id, full_name)')
        .eq('attendance_report_id', reportId)
        .order('marked_at');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> upsertReportItems({
    required String reportId,
    required List<Map<String, dynamic>> items,
    required String markedBy,
  }) async {
    for (final item in items) {
      await _supabase.from('attendance_report_items').upsert({
        'attendance_report_id': reportId,
        'rider_id': item['rider_id'],
        'rider_name': item['rider_name'],
        'rider_iqama': item['rider_iqama'],
        'attendance_status': item['attendance_status'],
        'absence_reason': item['absence_reason'],
        'is_carry_over': item['is_carry_over'] ?? false,
        'is_manual_addition': item['is_manual_addition'] ?? false,
        'manual_addition_reason': item['manual_addition_reason'],
        'marked_by': markedBy,
      });
    }
  }

  Future<void> submitSOS({
    required String reportId,
    required List<Map<String, dynamic>> items,
    required String markedBy,
    String? handoverNotes,
  }) async {
    await upsertReportItems(reportId: reportId, items: items, markedBy: markedBy);
    await _supabase.from('attendance_reports').update({
      'status': 'SOS_SUBMITTED',
      'sos_submitted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  /// Returns true if any other SOS_SUBMITTED report exists for the same
  /// group+platform, indicating the next supervisor has clocked in.
  Future<bool> checkNextSupervisorSOS({
    required String currentReportId,
    required String groupId,
    required String platformId,
  }) async {
    try {
      final res = await _supabase
          .from('attendance_reports')
          .select('id')
          .eq('group_id', groupId)
          .eq('platform_id', platformId)
          .eq('status', 'SOS_SUBMITTED')
          .neq('id', currentReportId)
          .limit(1);
      return (res as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> submitEOS(String reportId, {String? handoverNotes}) async {
    await _supabase.from('attendance_reports').update({
      'status': 'EOS_SUBMITTED',
      'eos_submitted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  Future<void> uploadPlatformReport({
    required String reportId,
    required String supervisorId,
    required String platformId,
    required DateTime uploadDate,
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) async {
    await _supabase.from('platform_report_uploads').insert({
      'attendance_report_id': reportId,
      'supervisor_id': supervisorId,
      'platform_id': platformId,
      'upload_date': _fmtDate(uploadDate),
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'status': 'uploaded',
    });
    await _supabase.from('attendance_reports').update({
      'status': 'PENDING_ANALYSIS',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  /// Runs all validation checks in-process and persists flags.
  Future<List<Map<String, dynamic>>> runValidation(String reportId) async {
    final report = await _supabase
        .from('attendance_reports')
        .select()
        .eq('id', reportId)
        .maybeSingle();

    if (report == null) return [];

    final items = await _supabase
        .from('attendance_report_items')
        .select()
        .eq('attendance_report_id', reportId);

    final uploads = await _supabase
        .from('platform_report_uploads')
        .select('id')
        .eq('attendance_report_id', reportId);

    final flags = <Map<String, dynamic>>[];

    // Missing absence reasons
    for (final item in items as List) {
      if (item['attendance_status'] == 'absent' &&
          (item['absence_reason'] == null ||
              (item['absence_reason'] as String).trim().isEmpty)) {
        flags.add({
          'attendance_report_id': reportId,
          'flag_type': 'MISSING_REASON',
          'description':
              'Missing absence reason for ${item['rider_name'] ?? 'rider'}',
          'rider_id': item['rider_id'],
        });
      }
      if (item['is_manual_addition'] == true) {
        flags.add({
          'attendance_report_id': reportId,
          'flag_type': 'MANUAL_ADDED_RIDER',
          'description':
              'Manually added rider: ${item['rider_name']} — requires review',
          'rider_id': item['rider_id'],
        });
      }
    }

    if (report['sos_submitted_at'] == null) {
      flags.add({
        'attendance_report_id': reportId,
        'flag_type': 'MISSING_SOS',
        'description': 'SOS (start-of-shift) was not submitted',
      });
    }
    if (report['eos_submitted_at'] == null) {
      flags.add({
        'attendance_report_id': reportId,
        'flag_type': 'MISSING_EOS',
        'description': 'EOS (end-of-shift) was not submitted',
      });
    }
    if ((uploads as List).isEmpty) {
      flags.add({
        'attendance_report_id': reportId,
        'flag_type': 'MISSING_PLATFORM_REPORT',
        'description': 'Platform report file was not uploaded',
      });
    }

    // Replace existing flags
    await _supabase
        .from('validation_flags')
        .delete()
        .eq('attendance_report_id', reportId);

    final newStatus = flags.isEmpty ? 'APPROVED' : 'NEEDS_CORRECTION';
    if (flags.isNotEmpty) {
      await _supabase.from('validation_flags').insert(flags);
    }

    await _supabase.from('attendance_reports').update({
      'status': newStatus,
      'report_generated': flags.isEmpty,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);

    return flags;
  }

  Future<List<Map<String, dynamic>>> fetchValidationFlags(
      String reportId) async {
    final res = await _supabase
        .from('validation_flags')
        .select()
        .eq('attendance_report_id', reportId)
        .eq('is_resolved', false)
        .order('created_at');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> updateReportCorrectionNotes(
      String reportId, String notes) async {
    await _supabase.from('attendance_reports').update({
      'correction_notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  /// Returns open/in-progress support tickets for the given rider IDs.
  Future<List<Map<String, dynamic>>> fetchRiderIncidents(
      List<String> riderIds) async {
    if (riderIds.isEmpty) return [];
    final res = await _supabase
        .from('support_tickets')
        .select('*, profiles!support_tickets_profile_id_fkey(full_name)')
        .inFilter('profile_id', riderIds)
        .inFilter('status', ['open', 'in_progress'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Returns approved leave requests that cover [date] for the given rider IDs.
  Future<List<Map<String, dynamic>>> fetchRiderLeaveRequests(
      List<String> riderIds, DateTime date) async {
    if (riderIds.isEmpty) return [];
    final dateStr = _fmtDate(date);
    final res = await _supabase
        .from('requests')
        .select('*, profiles!requests_profile_id_fkey(full_name)')
        .inFilter('profile_id', riderIds)
        .eq('type', 'leave')
        .eq('status', 'approved')
        .lte('start_date', dateStr)
        .or('end_date.gte.$dateStr,end_date.is.null')
        .order('start_date', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Returns all pending requests from the given rider IDs.
  Future<List<Map<String, dynamic>>> fetchRiderPendingRequests(
      List<String> riderIds) async {
    if (riderIds.isEmpty) return [];
    final res = await _supabase
        .from('requests')
        .select('*, profiles!requests_profile_id_fkey(full_name)')
        .inFilter('profile_id', riderIds)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
