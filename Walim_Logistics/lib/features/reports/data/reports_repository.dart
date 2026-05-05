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
        .from('platform_compliance_reports')
        .select('*, platforms(name), profiles:supervisor_id(full_name)');

    if (platformId != null) query = query.eq('platform_id', platformId);
    if (supervisorId != null) query = query.eq('supervisor_id', supervisorId);
    if (frequency != null) query = query.eq('frequency', frequency.name);
    
    if (startDate != null) {
      query = query.gte('report_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('report_date', endDate.toIso8601String().split('T')[0]);
    }

    final res = await query.order('report_date', ascending: false);
    return (res as List).map((json) => PlatformReport.fromJson(json)).toList();
  }

  Future<void> uploadReport(PlatformReport report) async {
    await _supabase.from('platform_compliance_reports').insert(report.toJson());
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
    return platforms.values.toList()..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  Future<List<Map<String, dynamic>>> fetchSupervisors() async {
    final res = await _supabase
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'Supervisor')
        .order('full_name');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> fetchMissingReports({
    required DateTime date,
    required ReportFrequency frequency,
  }) async {
    // This would ideally be a RPC call or a complex query joining platforms and supervisors
    // For now, let's return a placeholder that we can implement logic for in the notifier
    return [];
  }
}
