import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

final financeRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FinanceRepository(supabase);
});



final financeStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.watch(financeRepositoryProvider).getFinanceStats();
});





final upcomingInvoicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(financeRepositoryProvider).getUpcomingInvoices();
});

final platformsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // Use supabase directly or via a repository if preferred. 
  // Since we already have financeRepositoryProvider, we could use it if it had the method.
  // But OperationsRepository already has fetchPlatforms.
  final supabase = ref.watch(supabaseProvider);
  final res = await supabase.from('platforms').select('id, name').order('name');
  return List<Map<String, dynamic>>.from(res as List);
});

final reconciliationByPlatformProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, platformId) async {
  // Placeholder as the original COD-based reconciliation was removed.
  return [];
});


