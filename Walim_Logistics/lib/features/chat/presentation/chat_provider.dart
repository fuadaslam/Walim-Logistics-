import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import '../data/chat_repository.dart';
import '../models/chat_message.dart';

final chatRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ChatRepository(supabase);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatRepository _repo;
  final String currentUserId;
  final String otherUserId;
  RealtimeChannel? _channel;

  ChatNotifier(this._repo, this.currentUserId, this.otherUserId) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final messages = await _repo.getMessages(currentUserId, otherUserId);
    if (!mounted) return;
    state = messages;
    await _repo.markMessagesRead(currentUserId, otherUserId);
    _subscribe();
  }

  void _subscribe() {
    _channel = _repo.subscribeToMessages(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      onMessage: (msg) {
        if (!mounted) return;
        state = [...state, msg];
        _repo.markMessagesRead(currentUserId, otherUserId);
      },
    );
  }

  Future<void> send(String message) async {
    if (message.trim().isEmpty) return;
    await _repo.sendMessage(
      senderId: currentUserId,
      receiverId: otherUserId,
      message: message.trim(),
    );
    final messages = await _repo.getMessages(currentUserId, otherUserId);
    if (!mounted) return;
    state = messages;
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.autoDispose.family<ChatNotifier, List<ChatMessage>, String>(
  (ref, otherUserId) {
    final repo = ref.watch(chatRepositoryProvider);
    final currentUser = ref.watch(authProvider).profile;
    return ChatNotifier(repo, currentUser?.id ?? '', otherUserId);
  },
);
