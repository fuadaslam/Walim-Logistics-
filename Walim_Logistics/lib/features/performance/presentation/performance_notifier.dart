import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/performance_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

final performanceRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return PerformanceRepository(supabase);
});

final riderLeaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(performanceRepositoryProvider).getLeaderboard('Rider');
});

final supervisorLeaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(performanceRepositoryProvider).getLeaderboard('Supervisor');
});

final myPerformanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return {};
  return ref.watch(performanceRepositoryProvider).getMyPerformance(profile.id);
});

final myTargetsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return [];
  return ref.watch(performanceRepositoryProvider).getTargets(profile.id);
});

final myAdjustmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(authProvider).profile;
  if (profile == null) return [];
  return ref.watch(performanceRepositoryProvider).getPenaltiesAndBonuses(profile.id);
});

final allAdjustmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(performanceRepositoryProvider).getAllPenaltiesAndBonuses();
});

final staffTargetsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, profileId) async {
  if (profileId.isEmpty) return [];
  return ref.watch(performanceRepositoryProvider).getTargets(profileId);
});

final staffAdjustmentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, profileId) async {
  if (profileId.isEmpty) return [];
  return ref.watch(performanceRepositoryProvider).getPenaltiesAndBonuses(profileId);
});
