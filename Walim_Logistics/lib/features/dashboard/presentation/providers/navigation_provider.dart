import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardTab {
  dashboard,
  liveOps,
  hr,
  assets,
  finance,
  attendance,
  inspections,
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
  NavigationNotifier() : super(NavigationState());

  void setTab(DashboardTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed);
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
