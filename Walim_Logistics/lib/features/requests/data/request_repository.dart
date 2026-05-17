import 'package:supabase_flutter/supabase_flutter.dart';

class RequestRepository {
  final SupabaseClient _supabase;

  RequestRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getRequestsForProfile(String profileId) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('requests')
          .select('*, profiles!requests_reviewed_by_fkey(full_name)')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('requests')
          .select('*, profiles!requests_profile_id_fkey(full_name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false),
    );
  }

  Future<void> createRequest({
    required String profileId,
    required String type,
    required String subject,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? photoUrls,
  }) async {
    await _supabase.from('requests').insert({
      'profile_id': profileId,
      'type': type,
      'subject': subject,
      'description': description,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'photo_urls': photoUrls ?? [],
      'status': 'pending',
    });
  }

  Future<void> reviewRequest({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    await _supabase.from('requests').update({
      'status': status,
      'reviewed_by': reviewedBy,
      'review_note': reviewNote,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<void> cancelRequest(String requestId) async {
    await _supabase.from('requests').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}
