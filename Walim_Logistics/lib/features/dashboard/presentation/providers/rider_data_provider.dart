import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/fleet/data/fleet_repository.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/hr/data/document_repository.dart';

final fleetRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FleetRepository(supabase);
});

final riderZoneProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return null;
  return ref.watch(fleetRepositoryProvider).getRiderCurrentZone(profile.id);
});

final riderAssetsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return [];
  return ref.watch(fleetRepositoryProvider).getAssetsForProfile(profile.id);
});

final riderLeaveRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return [];
  return ref
      .watch(hrRepositoryProvider)
      .getLeaveRequestsForProfile(profile.id, limit: 4);
});

final riderIqamaExpiryProvider = FutureProvider<DateTime?>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return null;
  final repo = DocumentRepository(ref.watch(supabaseProvider));
  return repo.getDocumentExpiry(profile.id, 'Iqama / National ID');
});

final riderRecentAttendanceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return [];
  final supabase = ref.watch(supabaseProvider);
  final today = DateTime.now();
  final startOfDay =
      DateTime(today.year, today.month, today.day).toIso8601String();
  return await supabase
      .from('attendance')
      .select()
      .eq('profile_id', profile.id)
      .gte('check_in_time', startOfDay)
      .order('check_in_time', ascending: false)
      .limit(3);
});
