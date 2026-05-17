import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentRepository {
  final SupabaseClient _supabase;

  DocumentRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getDocuments(String profileId) async {
    return await _supabase
        .from('documents')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
  }

  Future<void> upsertDocument({
    required String profileId,
    String? id,
    required String title,
    required String type,
    String? status,
    DateTime? expiryDate,
    String? fileUrl,
    String? notes,
  }) async {
    final data = {
      'profile_id': profileId,
      'title': title,
      'type': type,
      'status': status ?? 'Valid',
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'file_url': fileUrl,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (id != null) {
      await _supabase.from('documents').update(data).eq('id', id);
    } else {
      await _supabase.from('documents').insert(data);
    }
  }

  Future<void> deleteDocument(String id) async {
    await _supabase.from('documents').delete().eq('id', id);
  }

  Future<void> updateStatus(String id, String status,
      {DateTime? expiryDate}) async {
    final data = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (expiryDate != null) {
      data['expiry_date'] = expiryDate.toIso8601String().split('T')[0];
    }
    await _supabase.from('documents').update(data).eq('id', id);
  }

  Future<DateTime?> getDocumentExpiry(String profileId, String type) async {
    try {
      final response = await _supabase
          .from('documents')
          .select('expiry_date')
          .eq('profile_id', profileId)
          .eq('type', type)
          .maybeSingle();
      if (response != null && response['expiry_date'] != null) {
        return DateTime.tryParse(response['expiry_date'].toString());
      }
    } catch (_) {}
    return null;
  }
}
