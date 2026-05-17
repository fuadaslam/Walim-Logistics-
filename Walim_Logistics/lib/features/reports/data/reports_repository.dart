import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/platform_report.dart';

class ReportsRepository {
  final SupabaseClient _supabase;

  ReportsRepository(this._supabase);

  Future<List<PlatformReport>> fetchReports({
    String? platformId,
    String? supervisorId,
    ReportFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('platform_report_uploads')
        .select('*, platforms(name), profiles!supervisor_id(full_name)');

    if (platformId != null) query = query.eq('platform_id', platformId);
    if (supervisorId != null) query = query.eq('supervisor_id', supervisorId);

    if (frequency != null) {
      final now = DateTime.now();
      final start = startDate ?? now;
      if (frequency == ReportFrequency.daily) {
        final dateStr = start.toIso8601String().split('T')[0];
        query = query.eq('upload_date', dateStr);
      } else if (frequency == ReportFrequency.weekly) {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        query = query
            .gte('upload_date', weekStart.toIso8601String().split('T')[0])
            .lte('upload_date', weekEnd.toIso8601String().split('T')[0]);
      } else if (frequency == ReportFrequency.monthly) {
        final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
        final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T')[0];
        query = query.gte('upload_date', monthStart).lte('upload_date', monthEnd);
      }
    } else {
      if (startDate != null) {
        query = query.gte('upload_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('upload_date', endDate.toIso8601String().split('T')[0]);
      }
    }

    final res = await query.order('uploaded_at', ascending: false);
    return (res as List).map((json) => PlatformReport.fromJson(json)).toList();
  }

  Future<void> uploadReport(PlatformReport report) async {
    await _supabase.from('platform_report_uploads').insert(report.toJson());
  }

  Future<String> uploadReportFile({
    required Uint8List fileBytes,
    required String fileName,
    required String userId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'reports/$userId/${timestamp}_$fileName';

    await _supabase.storage.from('fleet_assets').uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    return _supabase.storage.from('fleet_assets').getPublicUrl(path);
  }

  Future<List<Map<String, dynamic>>> fetchPlatforms() async {
    final res = await _supabase
        .from('platforms')
        .select('id, name')
        .order('name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchAssignedPlatforms(String supervisorId) async {
    final res = await _supabase
        .from('groups')
        .select('platforms(id, name)')
        .eq('supervisor_id', supervisorId)
        .eq('is_active', true);

    final platforms = <String, Map<String, dynamic>>{};
    for (var item in (res as List)) {
      final p = item['platforms'] as Map<String, dynamic>?;
      if (p != null) {
        platforms[p['id'] as String] = p;
      }
    }
    return platforms.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  Future<List<Map<String, dynamic>>> fetchSupervisors() async {
    final roleId = await _getRoleId('Supervisor');
    if (roleId == null) return [];

    final res = await _supabase
        .from('profiles')
        .select('id, full_name')
        .eq('role_id', roleId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<String?> _getRoleId(String roleName) async {
    final res = await _supabase
        .from('roles')
        .select('id')
        .eq('name', roleName)
        .maybeSingle();
    if (res != null) return res['id'] as String;

    final resAlt = await _supabase
        .from('roles')
        .select('id')
        .ilike('name', roleName)
        .maybeSingle();
    return resAlt?['id'] as String?;
  }

  Future<List<Map<String, dynamic>>> fetchMissingReports({
    required DateTime date,
    required ReportFrequency frequency,
  }) async {
    return [];
  }
}
