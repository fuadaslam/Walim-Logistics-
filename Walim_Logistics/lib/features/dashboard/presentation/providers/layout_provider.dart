import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/core/providers/shared_prefs_provider.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/data/models/dashboard_layout.dart';

final dashboardLayoutProvider = StateNotifierProvider<DashboardLayoutNotifier, DashboardLayout>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.profile?.role ?? 'Rider';
  return DashboardLayoutNotifier(ref, role);
});

class DashboardLayoutNotifier extends StateNotifier<DashboardLayout> {
  final Ref _ref;
  final String _role;

  DashboardLayoutNotifier(this._ref, this._role) : super(DashboardLayout.defaultLayout(_role)) {
    _loadLayout();
  }

  static String _getStorageKey(String role) => 'dashboard_layout_$role';

  void _loadLayout() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final savedLayout = prefs.getString(_getStorageKey(_role));
      if (savedLayout != null) {
        state = DashboardLayout.fromJson(savedLayout);
      }
    } catch (e) {
      // Fallback to default
    }
  }

  Future<void> updateLayout(DashboardLayout newLayout) async {
    state = newLayout;
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(_getStorageKey(_role), newLayout.toJson());
  }

  Future<void> toggleSection(DashboardSection section) async {
    List<DashboardSection> newSections = List.from(state.sections);
    List<DashboardSection> newHidden = List.from(state.hiddenSections);

    if (newSections.contains(section)) {
      newSections.remove(section);
      newHidden.add(section);
    } else {
      newHidden.remove(section);
      newSections.add(section);
    }

    final newLayout = state.copyWith(
      sections: newSections,
      hiddenSections: newHidden,
    );
    await updateLayout(newLayout);
  }

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final List<DashboardSection> newSections = List.from(state.sections);
    final section = newSections.removeAt(oldIndex);
    newSections.insert(newIndex, section);

    final newLayout = state.copyWith(sections: newSections);
    await updateLayout(newLayout);
  }

  Future<void> resetToDefault() async {
    final defaultLayout = DashboardLayout.defaultLayout(_role);
    await updateLayout(defaultLayout);
  }
}
