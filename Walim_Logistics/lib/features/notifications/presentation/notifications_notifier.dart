import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/notifications/data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return NotificationsRepository(supabase);
});

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return Stream.value([]);
  return ref
      .watch(notificationsRepositoryProvider)
      .streamNotifications(profile.id);
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications =
      ref.watch(notificationsStreamProvider).valueOrNull ?? [];
  return notifications.where((n) => n['is_read'] == false).length;
});
