import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<Map<String, dynamic>> getGlobalMetrics() async {
    final rolesResponse = await _supabase.from('roles').select('id, name');
    final roles = rolesResponse as List;
    final riderRoleId = roles.firstWhere((r) => r['name'] == 'Rider', orElse: () => {'id': ''})['id'];
    final supervisorRoleId = roles.firstWhere((r) => r['name'] == 'Supervisor', orElse: () => {'id': ''})['id'];

    final today = DateTime.now();
    final dateStr = today.toIso8601String().split('T')[0];
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    final results = await Future.wait<dynamic>([
      _supabase.from('profiles').select('id').eq('role_id', riderRoleId).eq('status', 'active'),
      _supabase.from('profiles').select('id').eq('role_id', riderRoleId).eq('status', 'inactive'),
      _supabase.from('profiles').select('id').eq('role_id', riderRoleId).eq('status', 'leave'),
      _supabase.from('profiles').select('id').eq('role_id', supervisorRoleId).eq('status', 'active'),
      _supabase.from('incidents').select('id').or('status.eq.pending,status.eq.investigating'),
      _supabase.from('groups').select('id').eq('is_active', true),
      _supabase.from('vehicles').select('status'),
      _supabase.from('platforms').select('id, name'),
      _supabase.from('attendance').select('id').gte('check_in_time', startOfDay),
      _supabase.from('attendance').select('id').gte('check_out_time', startOfDay),
      _supabase.from('rider_shift_plans').select('rider_id').eq('shift_date', dateStr),
      _supabase.from('inspections').select('profile_id').gte('created_at', startOfDay),
    ]);

    final activeRiders = (results[0] as List).length;
    final inactiveRiders = (results[1] as List).length;
    final ridersOnLeave = (results[2] as List).length;
    final supervisorsCount = (results[3] as List).length;
    final activeIncidents = (results[4] as List).length;
    final activeGroups = (results[5] as List).length;
    
    final vehicles = results[6] as List;
    final totalVehicles = vehicles.length;
    final availableVehicles = vehicles.where((v) => v['status'] == 'available').length;
    final assetHealth = totalVehicles > 0 ? (availableVehicles / totalVehicles * 100).toInt() : 0;

    final checkedInToday = (results[8] as List).length;
    final checkedOutToday = (results[9] as List).length;
    final plannedShifts = (results[10] as List).length;
    final inspectionsDone = (results[11] as List).length;
    final pendingInspections = plannedShifts > inspectionsDone ? plannedShifts - inspectionsDone : 0;

    // Fetch riders_per_supervisor setting
    final settingsResponse = await _supabase.from('system_settings').select('value').eq('key', 'riders_per_supervisor').maybeSingle();
    final ridersPerGroup = int.tryParse(settingsResponse?['value'] ?? '30') ?? 30;
    final peakCapacity = activeGroups * ridersPerGroup;

    // Fetch platform distribution
    final platformCounts = await _supabase.from('groups').select('platform_id, platforms(name, id)');
    final Map<String, Map<String, dynamic>> distribution = {};
    for (var g in platformCounts as List) {
      final platforms = g['platforms'];
      if (platforms == null) continue;
      
      final String name;
      if (platforms is List && platforms.isNotEmpty) {
        name = platforms[0]['name'] ?? 'Unknown';
      } else if (platforms is Map) {
        name = platforms['name'] ?? 'Unknown';
      } else {
        continue;
      }

      distribution[name] = {
        'name': name,
        'count': (distribution[name]?['count'] ?? 0) + 1,
        'color': _getPlatformColor(name),
      };
    }
    
    final totalGroups = activeGroups > 0 ? activeGroups : 1;
    final platformShare = distribution.values.map((v) => {
      ...v,
      'share': (v['count'] as int) / totalGroups,
    }).toList();

    return {
      'activeRiders': activeRiders,
      'inactiveRiders': inactiveRiders,
      'ridersOnLeave': ridersOnLeave,
      'supervisorsCount': supervisorsCount,
      'activeIncidents': activeIncidents,
      'activeGroups': activeGroups,
      'assetHealth': assetHealth,
      'platforms': results[7] as List,
      'checkedInToday': checkedInToday,
      'checkedOutToday': checkedOutToday,
      'pendingInspections': pendingInspections,
      'peakCapacity': peakCapacity,
      'platformShare': platformShare,
    };
  }

  Future<List<Map<String, dynamic>>> getFleetAssets() async {
    final response = await _supabase
        .from('vehicles')
        .select('*, profiles(full_name, avatar_url, iqama_number, roles(name))')
        .order('plate_number');
    
    return (response as List).map((v) => {
      'id': v['id'],
      'plate': v['plate_number'],
      'type': v['type'] == 'bike' ? 'Bike' : 'Van',
      'status': v['status'][0].toUpperCase() + v['status'].substring(1),
      'mvpi': v['mvpi_expiry'] ?? 'N/A',
      'insurance': v['insurance_expiry'] ?? 'N/A',
      'assignedTo': v['profiles']?['full_name'] ?? 'Unassigned',
      'iqamaNumber': v['profiles']?['iqama_number'] ?? 'N/A',
      'role': v['profiles']?['roles']?['name'] ?? '',
      'avatar': v['profiles']?['avatar_url'] ?? 'https://i.pravatar.cc/150?u=${v['id']}',
    }).toList();
  }

  Color _getPlatformColor(String name) {
    switch (name.toLowerCase()) {
      case 'noon': return Colors.amber;
      case 'keeta': return Colors.teal;
      case 'amazon': return Colors.orange;
      case 'hungerstation': return Colors.red;
      default: return Colors.blue;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final results = await Future.wait([
        _supabase.from('incidents').select('*, profiles!reported_by(full_name)').order('created_at', ascending: false).limit(2),
        _supabase.from('leave_requests').select('*, profiles!profile_id(full_name)').order('created_at', ascending: false).limit(2),
        _supabase.from('inspections').select('*, profiles(full_name)').order('created_at', ascending: false).limit(2),
      ]);

      final incidents = (results[0] as List).map((i) => {
        'title': 'New Incident: ${i['type'] ?? 'General'}',
        'subtitle': 'Reported by ${i['profiles']?['full_name'] ?? 'Unknown Staff'}',
        'time': _formatTime(i['created_at'] ?? DateTime.now().toIso8601String()),
        'type': 'incident',
        'status': i['status'] ?? 'pending',
      }).toList();

      final leaves = (results[1] as List).map((l) => {
        'title': 'Leave Request: ${l['type'] ?? 'General'}',
        'subtitle': '${l['profiles']?['full_name'] ?? 'Unknown Staff'} requested leave',
        'time': _formatTime(l['created_at'] ?? DateTime.now().toIso8601String()),
        'type': 'leave',
        'status': l['status'] ?? 'pending',
      }).toList();

      final inspections = (results[2] as List).map((ins) => {
        'title': 'Inspection ${ins['is_safe_to_drive'] == true ? 'Passed' : 'Failed'}',
        'subtitle': 'By ${ins['profiles']?['full_name'] ?? 'Unknown Staff'}',
        'time': _formatTime(ins['created_at'] ?? DateTime.now().toIso8601String()),
        'type': 'inspection',
        'status': ins['is_safe_to_drive'] == true ? 'Passed' : 'Failed',
      }).toList();

      final allActivity = [...incidents, ...leaves, ...inspections];
      allActivity.sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
      return allActivity;
    } catch (e) {
      debugPrint('Error fetching recent activity: $e');
      return [];
    }
  }

  String _formatTime(String isoDate) {
    final date = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
