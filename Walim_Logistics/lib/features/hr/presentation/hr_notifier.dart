import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hr_repository.dart';
import '../../auth/presentation/auth_notifier.dart';

final hrRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return HRRepository(supabase);
});

class HRStats {
  final int totalStaff;
  final int pendingLeaves;
  final int complianceAlerts;
  final bool isLoading;
  final String? error;

  const HRStats({
    this.totalStaff = 0,
    this.pendingLeaves = 0,
    this.complianceAlerts = 0,
    this.isLoading = false,
    this.error,
  });

  HRStats copyWith({
    int? totalStaff,
    int? pendingLeaves,
    int? complianceAlerts,
    bool? isLoading,
    String? error,
  }) {
    return HRStats(
      totalStaff: totalStaff ?? this.totalStaff,
      pendingLeaves: pendingLeaves ?? this.pendingLeaves,
      complianceAlerts: complianceAlerts ?? this.complianceAlerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HRStatsNotifier extends StateNotifier<HRStats> {
  final HRRepository _repository;

  HRStatsNotifier(this._repository) : super(const HRStats(isLoading: true)) {
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final stats = await _repository.getHRStats();
      state = state.copyWith(
        totalStaff: stats['totalStaff'] as int? ?? 0,
        pendingLeaves: stats['pendingLeaves'] as int? ?? 0,
        complianceAlerts: stats['complianceAlerts'] as int? ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final hrStatsProvider = StateNotifierProvider<HRStatsNotifier, HRStats>((ref) {
  final repo = ref.watch(hrRepositoryProvider);
  return HRStatsNotifier(repo);
});

final complianceAlertsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(hrRepositoryProvider).getComplianceAlerts();
});

final hrAllLeaveRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(hrRepositoryProvider).getAllLeaveRequests();
});

final hrRecentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(hrRepositoryProvider).getRecentActivity();
});

final allStaffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(hrRepositoryProvider).getAllStaff();
});

final onboardingStaffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(hrRepositoryProvider).getOnboardingStaff();
});

