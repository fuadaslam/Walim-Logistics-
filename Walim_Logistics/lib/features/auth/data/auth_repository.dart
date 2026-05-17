import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/profile.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('*, roles(name)')
        .eq('id', userId)
        .maybeSingle();
    
    if (response != null) {
      return UserProfile.fromJson(response);
    }
    return null;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
