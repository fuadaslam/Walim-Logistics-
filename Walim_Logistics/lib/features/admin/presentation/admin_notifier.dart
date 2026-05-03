import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

final adminRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AdminRepository(supabase);
});

class AdminStats {
  final int activeRiders;
  final int fleetHealth;
  final double pendingCod;
  final int liveOrders;
  final int onLeave;
  final int pendingRequests;
  final bool isLoading;
  final String? error;

  const AdminStats({
    this.activeRiders = 0,
    this.fleetHealth = 0,
    this.pendingCod = 0,
    this.liveOrders = 0,
    this.onLeave = 0,
    this.pendingRequests = 0,
    this.isLoading = false,
    this.error,
  });

  AdminStats copyWith({
    int? activeRiders,
    int? fleetHealth,
    double? pendingCod,
    int? liveOrders,
    int? onLeave,
    int? pendingRequests,
    bool? isLoading,
    String? error,
  }) {
    return AdminStats(
      activeRiders: activeRiders ?? this.activeRiders,
      fleetHealth: fleetHealth ?? this.fleetHealth,
      pendingCod: pendingCod ?? this.pendingCod,
      liveOrders: liveOrders ?? this.liveOrders,
      onLeave: onLeave ?? this.onLeave,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminStats> {
  final AdminRepository _repository;

  AdminNotifier(this._repository) : super(const AdminStats(isLoading: true)) {
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final stats = await _repository.getDashboardStats();
      state = state.copyWith(
        activeRiders: stats['activeRiders'] as int? ?? 0,
        fleetHealth: stats['fleetHealth'] as int? ?? 0,
        pendingCod: (stats['pendingCod'] as num?)?.toDouble() ?? 0,
        liveOrders: stats['liveOrders'] as int? ?? 0,
        onLeave: stats['onLeave'] as int? ?? 0,
        pendingRequests: stats['pendingRequests'] as int? ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminStatsProvider = StateNotifierProvider<AdminNotifier, AdminStats>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminNotifier(repo);
});

final auditLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAuditLogs();
});
