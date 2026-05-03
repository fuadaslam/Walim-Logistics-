import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';
import '../../../auth/presentation/auth_notifier.dart';

final dashboardRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return DashboardRepository(supabase);
});

class DashboardData {
  final int activeRiders;
  final int inactiveRiders;
  final int ridersOnLeave;
  final int activeIncidents;
  final int activeGroups;
  final int supervisorsCount;
  final int assetHealth;
  final int checkedInToday; // SOS
  final int checkedOutToday; // EOS
  final int pendingInspections;
  final int peakCapacity;
  final List<Map<String, dynamic>> platforms;
  final List<Map<String, dynamic>> platformShare;
  final List<Map<String, dynamic>> recentActivity;
  final List<Map<String, dynamic>> fleetAssets;
  final bool isLoading;
  final String? error;

  DashboardData({
    this.activeRiders = 0,
    this.inactiveRiders = 0,
    this.ridersOnLeave = 0,
    this.activeIncidents = 0,
    this.activeGroups = 0,
    this.supervisorsCount = 0,
    this.assetHealth = 0,
    this.checkedInToday = 0,
    this.checkedOutToday = 0,
    this.pendingInspections = 0,
    this.peakCapacity = 0,
    this.platforms = const [],
    this.platformShare = const [],
    this.recentActivity = const [],
    this.fleetAssets = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardData copyWith({
    int? activeRiders,
    int? inactiveRiders,
    int? ridersOnLeave,
    int? activeIncidents,
    int? activeGroups,
    int? supervisorsCount,
    int? assetHealth,
    int? checkedInToday,
    int? checkedOutToday,
    int? pendingInspections,
    int? peakCapacity,
    List<Map<String, dynamic>>? platforms,
    List<Map<String, dynamic>>? platformShare,
    List<Map<String, dynamic>>? recentActivity,
    List<Map<String, dynamic>>? fleetAssets,
    bool? isLoading,
    String? error,
  }) {
    return DashboardData(
      activeRiders: activeRiders ?? this.activeRiders,
      inactiveRiders: inactiveRiders ?? this.inactiveRiders,
      ridersOnLeave: ridersOnLeave ?? this.ridersOnLeave,
      activeIncidents: activeIncidents ?? this.activeIncidents,
      activeGroups: activeGroups ?? this.activeGroups,
      supervisorsCount: supervisorsCount ?? this.supervisorsCount,
      assetHealth: assetHealth ?? this.assetHealth,
      checkedInToday: checkedInToday ?? this.checkedInToday,
      checkedOutToday: checkedOutToday ?? this.checkedOutToday,
      pendingInspections: pendingInspections ?? this.pendingInspections,
      peakCapacity: peakCapacity ?? this.peakCapacity,
      platforms: platforms ?? this.platforms,
      platformShare: platformShare ?? this.platformShare,
      recentActivity: recentActivity ?? this.recentActivity,
      fleetAssets: fleetAssets ?? this.fleetAssets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardData> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(DashboardData(isLoading: true)) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final metrics = await _repository.getGlobalMetrics();
      final activity = await _repository.getRecentActivity();
      final assets = await _repository.getFleetAssets();

      state = state.copyWith(
        activeRiders: metrics['activeRiders'],
        inactiveRiders: metrics['inactiveRiders'],
        ridersOnLeave: metrics['ridersOnLeave'],
        activeIncidents: metrics['activeIncidents'],
        activeGroups: metrics['activeGroups'],
        supervisorsCount: metrics['supervisorsCount'],
        assetHealth: metrics['assetHealth'],
        checkedInToday: metrics['checkedInToday'],
        checkedOutToday: metrics['checkedOutToday'],
        pendingInspections: metrics['pendingInspections'],
        peakCapacity: metrics['peakCapacity'],
        platforms: List<Map<String, dynamic>>.from(metrics['platforms']),
        platformShare: List<Map<String, dynamic>>.from(metrics['platformShare'] ?? []),
        recentActivity: activity,
        fleetAssets: assets,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dashboardDataProvider = StateNotifierProvider<DashboardNotifier, DashboardData>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repo);
});
