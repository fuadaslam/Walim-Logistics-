import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/incidents/data/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return IncidentRepository(supabase);
});

final pendingIncidentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(incidentRepositoryProvider);
  return repo.getPendingIncidents();
});

class IncidentNotifier extends StateNotifier<AsyncValue<void>> {
  final IncidentRepository _repository;
  final Ref _ref;

  IncidentNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateStatus(String incidentId, String status) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) throw Exception('User not authenticated');

      await _repository.updateIncidentStatus(
        incidentId: incidentId,
        status: status,
        resolvedBy: user.id,
      );
      
      // Refresh the pending list
      _ref.invalidate(pendingIncidentsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final incidentNotifierProvider = StateNotifierProvider<IncidentNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(incidentRepositoryProvider);
  return IncidentNotifier(repository, ref);
});
