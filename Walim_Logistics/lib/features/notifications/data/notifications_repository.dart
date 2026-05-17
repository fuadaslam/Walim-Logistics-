import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRepository {
  final SupabaseClient _supabase;

  NotificationsRepository(this._supabase);

  Stream<List<Map<String, dynamic>>> streamNotifications(String profileId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String profileId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('profile_id', profileId)
        .eq('is_read', false);
  }
}
