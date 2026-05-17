import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/request_repository.dart';

class RequestState {
  final List<Map<String, dynamic>> requests;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final bool submitSuccess;

  const RequestState({
    this.requests = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitSuccess = false,
  });

  RequestState copyWith({
    List<Map<String, dynamic>>? requests,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? submitSuccess,
  }) {
    return RequestState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submitSuccess: submitSuccess ?? false,
    );
  }
}

class RequestNotifier extends StateNotifier<RequestState> {
  final Ref _ref;

  RequestNotifier(this._ref) : super(const RequestState(isLoading: true)) {
    _load();
  }

  RequestRepository get _repo => _ref.read(requestRepositoryProvider);

  Future<void> _load() async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      state = state.copyWith(isLoading: true, error: null);
      final requests = await _repo.getRequestsForProfile(profile.id);
      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<bool> submitRequest({
    required String type,
    required String subject,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? photoUrls,
  }) async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) return false;
    try {
      state = state.copyWith(isSubmitting: true, error: null);
      await _repo.createRequest(
        profileId: profile.id,
        type: type,
        subject: subject,
        description: description,
        startDate: startDate,
        endDate: endDate,
        photoUrls: photoUrls,
      );
      state = state.copyWith(isSubmitting: false, submitSuccess: true);
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<void> cancel(String requestId) async {
    try {
      await _repo.cancelRequest(requestId);
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class PendingRequestNotifier extends StateNotifier<RequestState> {
  final Ref _ref;

  PendingRequestNotifier(this._ref) : super(const RequestState(isLoading: true)) {
    _load();
  }

  RequestRepository get _repo => _ref.read(requestRepositoryProvider);

  Future<void> _load() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final requests = await _repo.getPendingRequests();
      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<void> reviewRequest({
    required String requestId,
    required String status,
    String? reviewNote,
  }) async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) return;
    try {
      await _repo.reviewRequest(
        requestId: requestId,
        status: status,
        reviewedBy: profile.id,
        reviewNote: reviewNote,
      );
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final requestRepositoryProvider = Provider((ref) {
  return RequestRepository(Supabase.instance.client);
});

final requestProvider =
    StateNotifierProvider<RequestNotifier, RequestState>((ref) {
  return RequestNotifier(ref);
});

final pendingRequestProvider =
    StateNotifierProvider<PendingRequestNotifier, RequestState>((ref) {
  return PendingRequestNotifier(ref);
});
