import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/app_role.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Gagal membuat akun');
    }

    await _supabase.from('users').insert({
      'id': user.id,
      'username': username,
      'email': email,
      'role': 'user',
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  Session? get currentSession {
    return _supabase.auth.currentSession;
  }

  Future<UserModel?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final Map<String, dynamic> data = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromJson(data);
  }

  Future<AppRole?> getRole() async {
    final profile = await getCurrentProfile();

    return profile?.role;
  }

  Future<bool> isLoggedIn() async {
    return currentSession != null;
  }
}

