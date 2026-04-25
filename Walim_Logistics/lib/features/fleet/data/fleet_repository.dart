import 'package:supabase_flutter/supabase_flutter.dart';

class FleetRepository {
  final SupabaseClient _supabase;

  FleetRepository(this._supabase);

  // Asset Management
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

    // Update asset status
    await _supabase.from('assets').update({
      'status': 'assigned',
    }).eq('id', assetId);
  }

  Future<List<Map<String, dynamic>>> getAssetsForProfile(String profileId) async {
    return await _supabase
        .from('assets')
        .select('*, asset_assignments!inner(*)')
        .eq('asset_assignments.profile_id', profileId)
        .filter('asset_assignments.returned_at', 'is', null);
  }

  // Shift Management
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
}
