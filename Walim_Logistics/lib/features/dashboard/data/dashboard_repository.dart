import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<Map<String, dynamic>> getGlobalMetrics() async {
    final riderRoleResponse = await _supabase.from('roles').select('id').eq('name', 'Rider').single();
    final riderRoleId = riderRoleResponse['id'];

    final today = DateTime.now();
    final dateStr = today.toIso8601String().split('T')[0];
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

    final results = await Future.wait<dynamic>([
      _supabase.from('profiles').select('id').eq('role_id', riderRoleId).eq('status', 'active'),
      _supabase.from('profiles').select('id').eq('role_id', riderRoleId).eq('status', 'inactive'),
      _supabase.from('incidents').select('id').or('status.eq.pending,status.eq.investigating'),
      _supabase.from('groups').select('id').eq('is_active', true),
      _supabase.from('vehicles').select('status'),
      _supabase.from('platforms').select('id, name'),
      _supabase.from('attendance').select('id').gte('check_in_time', startOfDay),
      _supabase.from('rider_shift_plans').select('rider_id').eq('shift_date', dateStr),
      _supabase.from('inspections').select('profile_id').gte('created_at', startOfDay),
    ]);

    final activeRiders = (results[0] as List).length;
    final inactiveRiders = (results[1] as List).length;
    final activeIncidents = (results[2] as List).length;
    final activeGroups = (results[3] as List).length;
    
    final vehicles = results[4] as List;
    final totalVehicles = vehicles.length;
    final availableVehicles = vehicles.where((v) => v['status'] == 'available').length;
    final assetHealth = totalVehicles > 0 ? (availableVehicles / totalVehicles * 100).toInt() : 0;

    final checkedInToday = (results[6] as List).length;
    final plannedShifts = (results[7] as List).length;
    final inspectionsDone = (results[8] as List).length;
    final pendingInspections = plannedShifts > inspectionsDone ? plannedShifts - inspectionsDone : 0;

    // Fetch riders_per_supervisor setting
    final settingsResponse = await _supabase.from('system_settings').select('value').eq('key', 'riders_per_supervisor').maybeSingle();
    final ridersPerGroup = int.tryParse(settingsResponse?['value'] ?? '30') ?? 30;
    final peakCapacity = activeGroups * ridersPerGroup;

    // Fetch platform distribution (simplified: count groups per platform)
    final platformCounts = await _supabase.from('groups').select('platform_id, platforms(name, id)');
    final Map<String, Map<String, dynamic>> distribution = {};
    for (var g in platformCounts as List) {
      final p = g['platforms'] as Map<String, dynamic>;
      final name = p['name'] as String;
      distribution[name] = {
        'name': name,
        'count': (distribution[name]?['count'] ?? 0) + 1,
        'color': _getPlatformColor(name),
      };
    }
    
    final totalGroups = activeGroups > 0 ? activeGroups : 1;
    final platformShare = distribution.values.map((v) => {
      ...v,
      'share': v['count'] / totalGroups,
    }).toList();

    return {
      'activeRiders': activeRiders,
      'inactiveRiders': inactiveRiders,
      'activeIncidents': activeIncidents,
      'activeGroups': activeGroups,
      'assetHealth': assetHealth,
      'platforms': results[5] as List,
      'checkedInToday': checkedInToday,
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
    final results = await Future.wait([
      _supabase.from('incidents').select('*, profiles!reported_by(full_name)').order('created_at', ascending: false).limit(2),
      _supabase.from('leave_requests').select('*, profiles!profile_id(full_name)').order('created_at', ascending: false).limit(2),
      _supabase.from('inspections').select('*, profiles(full_name)').order('created_at', ascending: false).limit(2),
    ]);

    final incidents = (results[0] as List).map((i) => {
      'title': 'New Incident: ${i['type']}',
      'subtitle': 'Reported by ${i['profiles']['full_name']}',
      'time': _formatTime(i['created_at']),
      'type': 'incident',
      'status': i['status'],
    }).toList();

    final leaves = (results[1] as List).map((l) => {
      'title': 'Leave Request: ${l['type']}',
      'subtitle': '${l['profiles']['full_name']} requested leave',
      'time': _formatTime(l['created_at']),
      'type': 'leave',
      'status': l['status'],
    }).toList();

    final inspections = (results[2] as List).map((ins) => {
      'title': 'Inspection ${ins['is_safe_to_drive'] ? 'Passed' : 'Failed'}',
      'subtitle': 'By ${ins['profiles']['full_name']}',
      'time': _formatTime(ins['created_at']),
      'type': 'inspection',
      'status': ins['is_safe_to_drive'] ? 'Passed' : 'Failed',
    }).toList();

    return [...incidents, ...leaves, ...inspections]..sort((a, b) => b['time'].compareTo(a['time']));
  }

  String _formatTime(String isoDate) {
    final date = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
