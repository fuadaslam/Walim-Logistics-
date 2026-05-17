import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/support_ticket_repository.dart';

class SupportTicketState {
  final List<Map<String, dynamic>> tickets;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final bool submitSuccess;

  const SupportTicketState({
    this.tickets = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitSuccess = false,
  });

  SupportTicketState copyWith({
    List<Map<String, dynamic>>? tickets,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? submitSuccess,
  }) {
    return SupportTicketState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submitSuccess: submitSuccess ?? false,
    );
  }
}

class SupportTicketNotifier extends StateNotifier<SupportTicketState> {
  final Ref _ref;

  SupportTicketNotifier(this._ref) : super(const SupportTicketState(isLoading: true)) {
    _load();
  }

  SupportTicketRepository get _repo => _ref.read(supportTicketRepositoryProvider);

  Future<void> _load() async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      state = state.copyWith(isLoading: true, error: null);
      final tickets = await _repo.getTicketsForProfile(profile.id);
      state = state.copyWith(tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<bool> createTicket({
    required String subject,
    required String type,
    required String priority,
    String? description,
    List<String>? photoUrls,
  }) async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) return false;
    try {
      state = state.copyWith(isSubmitting: true, error: null);
      await _repo.createTicket(
        profileId: profile.id,
        subject: subject,
        type: type,
        priority: priority,
        description: description,
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

  Future<void> updateStatus({
    required String ticketId,
    required String status,
  }) async {
    final profile = _ref.read(authProvider).profile;
    try {
      await _repo.updateTicketStatus(
        ticketId: ticketId,
        status: status,
        resolvedBy: profile?.id,
      );
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final supportTicketRepositoryProvider = Provider((ref) {
  return SupportTicketRepository(Supabase.instance.client);
});

final supportTicketProvider =
    StateNotifierProvider<SupportTicketNotifier, SupportTicketState>((ref) {
  return SupportTicketNotifier(ref);
});
