import 'package:supabase_flutter/supabase_flutter.dart';

class SupportTicketRepository {
  final SupabaseClient _supabase;

  SupportTicketRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getTicketsForProfile(String profileId) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('support_tickets')
          .select('*')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> getAllTickets() async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('support_tickets')
          .select('*, profiles!support_tickets_profile_id_fkey(full_name)')
          .order('created_at', ascending: false),
    );
  }

  Future<void> createTicket({
    required String profileId,
    required String subject,
    required String type,
    required String priority,
    String? description,
    List<String>? photoUrls,
  }) async {
    await _supabase.from('support_tickets').insert({
      'profile_id': profileId,
      'subject': subject,
      'type': type,
      'priority': priority,
      'description': description,
      'photo_urls': photoUrls ?? [],
      'status': 'open',
    });
  }

  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
    String? resolvedBy,
  }) async {
    await _supabase.from('support_tickets').update({
      'status': status,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (status == 'resolved') 'resolved_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }
}
