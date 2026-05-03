import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

final financeRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FinanceRepository(supabase);
});

final platformsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(financeRepositoryProvider).getPlatforms();
});

final reconciliationByPlatformProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, platformId) async {
  if (platformId.isEmpty) return [];
  return ref
      .watch(financeRepositoryProvider)
      .getReconciliationForPlatform(platformId);
});
