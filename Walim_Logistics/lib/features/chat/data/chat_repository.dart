import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  Future<List<ChatMessage>> getMessages(String currentUserId, String otherUserId) async {
    final data = await _supabase
        .from('chat_messages')
        .select()
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)')
        .order('created_at', ascending: true);

    return (data as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    await _supabase.from('chat_messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
    });
  }

  Future<void> markMessagesRead(String currentUserId, String otherUserId) async {
    await _supabase
        .from('chat_messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('receiver_id', currentUserId)
        .eq('sender_id', otherUserId)
        .isFilter('read_at', null);
  }

  RealtimeChannel subscribeToMessages({
    required String currentUserId,
    required String otherUserId,
    required void Function(ChatMessage) onMessage,
  }) {
    return _supabase
        .channel('chat_${currentUserId}_$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final msg = ChatMessage.fromJson(payload.newRecord);
            if (msg.senderId == otherUserId) {
              onMessage(msg);
            }
          },
        )
        .subscribe();
  }

  Future<int> getUnreadCount(String currentUserId, String otherUserId) async {
    final data = await _supabase
        .from('chat_messages')
        .select('id')
        .eq('receiver_id', currentUserId)
        .eq('sender_id', otherUserId)
        .isFilter('read_at', null);
    return (data as List).length;
  }
}
