import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/shared/models/assigned_asset.dart';

class FleetRepository {
  final SupabaseClient _supabase;

  FleetRepository(this._supabase);

  Future<void> assignAsset({
    required String assetId,
    required String profileId,
    required String assignedBy,
    String? condition,
  }) async {
    await _supabase.from('asset_assignments').insert({
      'asset_id': assetId,
      'profile_id': profileId,
      'assigned_by': assignedBy,
      'condition_on_assign': condition,
    });

    await _supabase.from('assets').update({
      'status': 'assigned',
    }).eq('id', assetId);
  }

  Future<List<AssignedAsset>> getAssetsForProfile(String profileId) async {
    final res = await _supabase
        .from('profile_active_assets')
        .select()
        .eq('profile_id', profileId)
        .order('assigned_at', ascending: false);
    return (res as List).map((e) => AssignedAsset.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> assignToShift({
    required String profileId,
    required String zoneId,
    required DateTime start,
    required DateTime end,
  }) async {
    await _supabase.from('shifts').insert({
      'profile_id': profileId,
      'zone_id': zoneId,
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
      'status': 'scheduled',
    });
  }

  Future<List<Map<String, dynamic>>> getZones() async {
    return await _supabase.from('zones').select();
  }

  Future<Map<String, dynamic>?> getRiderCurrentZone(String profileId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('shifts')
          .select('*, zones!inner(*)')
          .eq('profile_id', profileId)
          .or('status.eq.active,status.eq.scheduled')
          .lte('start_time', now)
          .gte('end_time', now)
          .maybeSingle();
      if (response != null && response['zones'] != null) {
        return response['zones'] as Map<String, dynamic>;
      }
    } catch (_) {}
    try {
      final today = DateTime.now();
      final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();
      final response = await _supabase
          .from('shifts')
          .select('*, zones!inner(*)')
          .eq('profile_id', profileId)
          .gte('start_time', todayStr)
          .order('start_time', ascending: true)
          .limit(1)
          .maybeSingle();
      if (response != null && response['zones'] != null) {
        return response['zones'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
