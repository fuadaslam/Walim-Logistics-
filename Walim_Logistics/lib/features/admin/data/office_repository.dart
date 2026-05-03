import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfficeRepository {
  final SupabaseClient _supabase;

  OfficeRepository(this._supabase);

  Future<void> requestOfficeCall({
    required String targetProfileId,
    required String requestedByProfileId,
  }) async {
    await _supabase.from('office_requests').insert({
      'target_profile_id': targetProfileId,
      'requested_by_profile_id': requestedByProfileId,
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOfficeRequests(String profileId) async {
    final response = await _supabase
        .from('office_requests')
        .select('*, profiles!requested_by_profile_id(full_name, role)')
        .eq('target_profile_id', profileId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> resolveRequest(String requestId) async {
    await _supabase
        .from('office_requests')
        .update({'status': 'resolved'})
        .eq('id', requestId);
  }
}

final officeRepositoryProvider = Provider<OfficeRepository>((ref) {
  return OfficeRepository(Supabase.instance.client);
});

final pendingOfficeRequestsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, profileId) {
  return ref.watch(officeRepositoryProvider).getPendingOfficeRequests(profileId);
});
