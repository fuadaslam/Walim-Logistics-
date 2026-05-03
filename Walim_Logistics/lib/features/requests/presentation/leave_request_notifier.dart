import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../hr/presentation/hr_notifier.dart';
import '../../auth/presentation/auth_notifier.dart';

class LeaveRequestState {
  final List<Map<String, dynamic>> requests;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final bool submitSuccess;

  const LeaveRequestState({
    this.requests = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitSuccess = false,
  });

  LeaveRequestState copyWith({
    List<Map<String, dynamic>>? requests,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? submitSuccess,
  }) {
    return LeaveRequestState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submitSuccess: submitSuccess ?? false,
    );
  }
}

class LeaveRequestNotifier extends StateNotifier<LeaveRequestState> {
  final Ref _ref;

  LeaveRequestNotifier(this._ref)
      : super(const LeaveRequestState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      state = state.copyWith(isLoading: true, error: null);
      final repo = _ref.read(hrRepositoryProvider);
      final requests = await repo.getLeaveRequestsForProfile(profile.id);
      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<bool> submit({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) return false;
    try {
      state = state.copyWith(isSubmitting: true, error: null);
      final repo = _ref.read(hrRepositoryProvider);
      await repo.submitLeaveRequest(
        profileId: profile.id,
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      state = state.copyWith(isSubmitting: false, submitSuccess: true);
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final leaveRequestProvider =
    StateNotifierProvider<LeaveRequestNotifier, LeaveRequestState>((ref) {
  return LeaveRequestNotifier(ref);
});
