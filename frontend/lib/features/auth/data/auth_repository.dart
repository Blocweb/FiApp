import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseService _service;

  AuthRepository({SupabaseService? service})
      : _service = service ?? SupabaseService();

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) {
    return _service.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) {
    return _service.signUpWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return _service.signOut();
  }

  User? currentUser() => _service.currentUser;

  Session? currentSession() => _service.currentSession;

  bool isLoggedIn() => _service.isLoggedIn;
}