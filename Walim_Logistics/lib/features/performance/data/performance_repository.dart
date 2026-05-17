import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceRepository {
  final SupabaseClient _supabase;

  PerformanceRepository(this._supabase);

  Future<void> addPenaltyOrBonus({
    required String profileId,
    required String type,
    required double amount,
    required String reason,
    required String category,
    required String issuedById,
    required String issuedByName,
    String? notes,
  }) async {
    await _supabase.from('penalties_bonuses').insert({
      'profile_id': profileId,
      'type': type,
      'amount': amount,
      'reason': reason,
      'category': category,
      'issued_by': issuedById,
      'issued_by_name': issuedByName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<void> setTarget({
    required String profileId,
    required String metric,
    required double targetValue,
    required String period,
    required String createdById,
  }) async {
    await _supabase.from('performance_targets').upsert({
      'profile_id': profileId,
      'metric': metric,
      'target_value': targetValue,
      'period': period,
      'created_by': createdById,
    }, onConflict: 'profile_id,metric,period');
  }

  Future<List<Map<String, dynamic>>> getTargets(String profileId) async {
    return await _supabase
        .from('performance_targets')
        .select()
        .eq('profile_id', profileId)
        .eq('period', 'monthly')
        .order('metric');
  }

  Future<List<Map<String, dynamic>>> getPenaltiesAndBonuses(String profileId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    return await _supabase
        .from('penalties_bonuses')
        .select()
        .eq('profile_id', profileId)
        .gte('created_at', monthStart)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getAllPenaltiesAndBonuses() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    return await _supabase
        .from('penalties_bonuses')
        .select('*, profiles!penalties_bonuses_profile_id_fkey(full_name, role:roles(name))')
        .gte('created_at', monthStart)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> getMyPerformance(String profileId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();

    // Fetch weights from system_settings
    double weightAtt = 40;

    double weightInc = 20;

    try {
      final weights = await _supabase.from('system_settings').select('key, value').inFilter('key', [
        'perf_weight_attendance',
        'perf_weight_incident',
      ]);
      for (var w in weights) {
        if (w['key'] == 'perf_weight_attendance') weightAtt = double.tryParse(w['value']) ?? 40;
        if (w['key'] == 'perf_weight_incident') weightInc = double.tryParse(w['value']) ?? 20;
      }
    } catch (e) {
      debugPrint('Error fetching weights: $e');
    }

    double attendanceScore = 0;
    double incidentScore = weightInc;
    double bonusTotal = 0;
    double penaltyTotal = 0;

    // Attendance this month
    try {
      final attendance = await _supabase
          .from('attendance')
          .select('check_in_time')
          .eq('profile_id', profileId)
          .gte('check_in_time', monthStart);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final workDays = (daysInMonth * 6 / 7).round();
      final presentDays = (attendance as List).length;
      attendanceScore = (presentDays / workDays).clamp(0.0, 1.0) * weightAtt;
    } catch (e) {
      debugPrint('Attendance score error: $e');
    }



    // Incidents this week
    try {
      final incidents = await _supabase
          .from('incidents')
          .select('id')
          .eq('reported_by', profileId)
          .gte('created_at', weekStartStr);
      incidentScore = (incidents as List).isEmpty ? weightInc : 0;
    } catch (e) {
      debugPrint('Incident score error: $e');
    }

    // Adjustments this month
    try {
      final adjustments = await _supabase
          .from('penalties_bonuses')
          .select('type, amount')
          .eq('profile_id', profileId)
          .gte('created_at', monthStart);
      for (final row in adjustments as List) {
        final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
        if (row['type'] == 'bonus') {
          bonusTotal += amt;
        } else {
          penaltyTotal += amt;
        }
      }
    } catch (e) {
      debugPrint('Adjustments error: $e');
    }

    final baseScore = attendanceScore + incidentScore;

    return {
      'attendanceScore': attendanceScore,
      'incidentScore': incidentScore,
      'bonusTotal': bonusTotal,
      'penaltyTotal': penaltyTotal,
      'baseScore': baseScore,
      'netAdjustment': bonusTotal - penaltyTotal,
      'maxScore': weightAtt + weightInc,
      'weightAtt': weightAtt,
      'weightInc': weightInc,
    };
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String roleName) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();

    // Fetch weights from system_settings
    double weightAtt = 40;

    double weightInc = 20;

    try {
      final weights = await _supabase.from('system_settings').select('key, value').inFilter('key', [
        'perf_weight_attendance',
        'perf_weight_incident',
      ]);
      for (var w in weights) {
        if (w['key'] == 'perf_weight_attendance') weightAtt = double.tryParse(w['value']) ?? 40;
        if (w['key'] == 'perf_weight_incident') weightInc = double.tryParse(w['value']) ?? 20;
      }
    } catch (e) {
      debugPrint('Error fetching weights: $e');
    }

    // Fetch all profiles for this role (all active status variants)
    List<dynamic> profiles = [];
    try {
      profiles = await _supabase
          .from('profiles')
          .select('id, full_name, role:roles(name)')
          .or('status.eq.active,status.eq.Active_Completed,status.eq.Active_Pending');
      profiles = profiles.where((p) {
        final role = p['role'];
        if (role is Map) return role['name'] == roleName;
        return role == roleName;
      }).toList();
    } catch (e) {
      debugPrint('Profiles fetch error: $e');
      return [];
    }

    if (profiles.isEmpty) return [];

    final profileIds = profiles.map((p) => p['id'] as String).toList();

    // Bulk fetch attendance
    Map<String, int> attendanceCounts = {};
    try {
      final att = await _supabase
          .from('attendance')
          .select('profile_id')
          .inFilter('profile_id', profileIds)
          .gte('check_in_time', monthStart);
      for (final r in att as List) {
        final id = r['profile_id'] as String;
        attendanceCounts[id] = (attendanceCounts[id] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('Bulk attendance error: $e');
    }



    // Bulk fetch incidents
    Set<String> profilesWithIncidents = {};
    try {
      final inc = await _supabase
          .from('incidents')
          .select('reported_by')
          .inFilter('reported_by', profileIds)
          .gte('created_at', weekStartStr);
      for (final r in inc as List) {
        profilesWithIncidents.add(r['reported_by'] as String);
      }
    } catch (e) {
      debugPrint('Bulk incidents error: $e');
    }

    // Bulk fetch adjustments
    Map<String, double> bonusTotals = {};
    Map<String, double> penaltyTotals = {};
    try {
      final adj = await _supabase
          .from('penalties_bonuses')
          .select('profile_id, type, amount')
          .inFilter('profile_id', profileIds)
          .gte('created_at', monthStart);
      for (final r in adj as List) {
        final id = r['profile_id'] as String;
        final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        if (r['type'] == 'bonus') {
          bonusTotals[id] = (bonusTotals[id] ?? 0) + amt;
        } else {
          penaltyTotals[id] = (penaltyTotals[id] ?? 0) + amt;
        }
      }
    } catch (e) {
      debugPrint('Bulk adjustments error: $e');
    }

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final workDays = (daysInMonth * 6 / 7).round();

    final result = profiles.map((p) {
      final id = p['id'] as String;
      final name = p['full_name'] as String? ?? 'Unknown';

      final present = attendanceCounts[id] ?? 0;
      final attScore = (present / workDays).clamp(0.0, 1.0) * weightAtt;



      final incScore = profilesWithIncidents.contains(id) ? 0.0 : weightInc;
      final bonus = bonusTotals[id] ?? 0;
      final penalty = penaltyTotals[id] ?? 0;
      final baseScore = attScore + incScore;

      return {
        'id': id,
        'name': name,
        'attendanceScore': attScore,
        'incidentScore': incScore,
        'bonusTotal': bonus,
        'penaltyTotal': penalty,
        'baseScore': baseScore,
        'netAdjustment': bonus - penalty,
        'maxScore': weightAtt + weightInc,
        'weightAtt': weightAtt,
        'weightInc': weightInc,
      };
    }).toList();

    result.sort((a, b) {
      final scoreA = (a['baseScore'] as double) + (a['netAdjustment'] as double) / 100;
      final scoreB = (b['baseScore'] as double) + (b['netAdjustment'] as double) / 100;
      return scoreB.compareTo(scoreA);
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllStaffForRole(String roleName) async {
    final profiles = await _supabase
        .from('profiles')
        .select('id, full_name, role:roles(name)')
        .or('status.eq.active,status.eq.Active_Completed,status.eq.Active_Pending');
    return (profiles as List).where((p) {
      final role = p['role'];
      if (role is Map) return role['name'] == roleName;
      return role == roleName;
    }).cast<Map<String, dynamic>>().toList();
  }
}
