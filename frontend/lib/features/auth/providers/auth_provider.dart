import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fiapp/core/debug/session_debug_log.dart';
import '../data/auth_repository.dart';
import '../../profile/presentation/providers/profile_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref, ref.read(authRepositoryProvider));
});

class AuthState {
  static const Object _unset = Object();

  final bool loading;
  final String? error;
  final User? user;
  final Session? session;

  const AuthState({
    this.loading = false,
    this.error,
    this.user,
    this.session,
  });

  AuthState copyWith({
    bool? loading,
    Object? error = _unset,
    Object? user = _unset,
    Object? session = _unset,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      user: identical(user, _unset) ? this.user : user as User?,
      session: identical(session, _unset) ? this.session : session as Session?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthRepository _repository;

  AuthNotifier(this._ref, this._repository)
      : super(AuthState(
          user: _repository.currentUser(),
          session: _repository.currentSession(),
        ));

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      logSupabaseSessionSnapshot('login.before signInWithPassword');
      final response =
          await _repository.login(email: email, password: password);
      logSupabaseSessionSnapshot(
        'login.after signInWithPassword',
        responseUser: response.user,
        responseSession: response.session,
      );

      if (response.session == null || response.user == null) {
        state = state.copyWith(
          loading: false,
          error: 'Correo o contraseña incorrectos.',
        );
        return;
      }

      state = state.copyWith(
        loading: false,
        session: response.session,
        user: response.user,
        error: null,
      );

      _ref.invalidate(profileProvider);
      logSupabaseSessionSnapshot('login.after profileProvider invalidate');
    } catch (error) {
      logSupabaseSessionSnapshot('login.error', extra: {'error': error});
      state = state.copyWith(
        loading: false,
        error: error is AuthException
            ? error.message
            : 'Ocurrió un error de conexión. Intenta de nuevo.',
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      logSupabaseSessionSnapshot('register.before signUp');
      final response =
          await _repository.register(email: email, password: password);
      logSupabaseSessionSnapshot(
        'register.after signUp',
        responseUser: response.user,
        responseSession: response.session,
      );

      if (response.session == null || response.user == null) {
        state = state.copyWith(
          loading: false,
          session: null,
          user: null,
          error: response.user == null
              ? 'No se pudo crear la cuenta. Revisa los datos e intenta de nuevo.'
              : 'Cuenta creada, pero Supabase no devolvio una sesion activa. Inicia sesion para continuar.',
        );
        _ref.invalidate(profileProvider);
        return;
      }

      state = state.copyWith(
        loading: false,
        session: response.session,
        user: response.user,
        error: null,
      );

      _ref.invalidate(profileProvider);
      logSupabaseSessionSnapshot('register.after profileProvider invalidate');
    } catch (error) {
      logSupabaseSessionSnapshot('register.error', extra: {'error': error});
      state = state.copyWith(
        loading: false,
        error: error is AuthException
            ? error.message
            : 'Ocurrió un error de conexión. Intenta de nuevo.',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(loading: true, error: null);
    logSupabaseSessionSnapshot('logout.before signOut');
    await _repository.logout();
    logSupabaseSessionSnapshot('logout.after signOut');

    state = state.copyWith(
      loading: false,
      session: null,
      user: null,
    );

    _ref.invalidate(profileProvider);
    logSupabaseSessionSnapshot('logout.after profileProvider invalidate');
  }

  User? currentUser() => _repository.currentUser();

  Session? currentSession() => _repository.currentSession();

  bool isLoggedIn() => _repository.isLoggedIn();
}
