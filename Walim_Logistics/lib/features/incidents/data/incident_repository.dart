import 'package:supabase_flutter/supabase_flutter.dart';

class IncidentRepository {
  final SupabaseClient _supabase;

  IncidentRepository(this._supabase);

  Future<void> reportIncident({
    required String profileId,
    required String type,
    required String description,
    List<String>? photoUrls,
  }) async {
    await _supabase.from('incidents').insert({
      'reported_by': profileId,
      'type': type,
      'description': description,
      'photo_urls': photoUrls ?? [],
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getPendingIncidents() async {
    return await _supabase
        .from('incidents')
        .select('*, profiles!inner(full_name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    required String resolvedBy,
  }) async {
    await _supabase.from('incidents').update({
      'status': status,
      'resolved_by': resolvedBy,
    }).eq('id', incidentId);
  }
}
