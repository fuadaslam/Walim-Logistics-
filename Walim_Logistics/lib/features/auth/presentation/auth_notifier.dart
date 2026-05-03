import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../../../shared/models/profile.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final authRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthRepository(supabase);
});

class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.profile, this.isLoading = false, this.error});

  AuthState copyWith({User? user, UserProfile? profile, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SupabaseClient _supabase;

  AuthNotifier(this._repository, this._supabase) : super(AuthState()) {
    _init();
  }

  void _init() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _fetchProfile(user);
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        if (session != null) {
          _fetchProfile(session.user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthState();
      }
    });
  }

  Future<void> _fetchProfile(User user) async {
    state = state.copyWith(user: user, isLoading: true);
    try {
      final profile = await _repository.getUserProfile(user.id);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signIn(email, password);
      // Profile will be fetched by the onAuthStateChange listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (e) {
      // Even if remote sign out fails, we should clear local state
    } finally {
      state = AuthState();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);
  return AuthNotifier(repository, supabase);
});
