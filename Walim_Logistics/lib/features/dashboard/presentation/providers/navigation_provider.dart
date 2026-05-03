import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walim_logistics/core/providers/shared_prefs_provider.dart';

enum DashboardTab {
  dashboard,
  liveOps,
  liveRider,
  hr,
  assets,
  finance,
  attendance,
  support,
  documents,
  requests,
  settings,
}

class NavigationState {
  final DashboardTab activeTab;
  final bool isSidebarCollapsed;
  
  NavigationState({
    this.activeTab = DashboardTab.dashboard,
    this.isSidebarCollapsed = false,
  });

  NavigationState copyWith({
    DashboardTab? activeTab,
    bool? isSidebarCollapsed,
  }) {
    return NavigationState(
      activeTab: activeTab ?? this.activeTab,
      isSidebarCollapsed: isSidebarCollapsed ?? this.isSidebarCollapsed,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  final SharedPreferences _prefs;
  static const _sidebarCollapsedKey = 'sidebar_collapsed';

  NavigationNotifier(this._prefs) : super(NavigationState()) {
    _loadState();
  }

  void _loadState() {
    final isCollapsed = _prefs.getBool(_sidebarCollapsedKey);
    if (isCollapsed != null) {
      state = state.copyWith(isSidebarCollapsed: isCollapsed);
    }
  }

  void setTab(DashboardTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> toggleSidebar() async {
    final newValue = !state.isSidebarCollapsed;
    state = state.copyWith(isSidebarCollapsed: newValue);
    await _prefs.setBool(_sidebarCollapsedKey, newValue);
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NavigationNotifier(prefs);
});
