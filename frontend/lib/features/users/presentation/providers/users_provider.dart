import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/core/network/api_error.dart';
import 'package:fiapp/features/users/data/services/user_api_service.dart';
import 'package:fiapp/features/users/domain/entities/app_user.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) => UserApiService());

/// Negocio y rol del usuario con sesión abierta (HU01 · T05).
///
/// Se invalida al iniciar o cerrar sesión para no mostrar el rol anterior.
final currentMembershipProvider = FutureProvider<CurrentMembership>((ref) {
  return ref.read(userApiServiceProvider).getCurrentMembership();
});

class UsersState {
  final List<AppUser> users;
  final bool isLoading;
  final String? error;

  const UsersState({this.users = const [], this.isLoading = false, this.error});

  UsersState copyWith({List<AppUser>? users, bool? isLoading, String? error}) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Lista de usuarios del negocio y acciones de gestión (HU01 · T02, T03, T06).
class UsersNotifier extends StateNotifier<UsersState> {
  final UserApiService _service;

  UsersNotifier(this._service) : super(const UsersState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _service.getUsers();
      if (!mounted) return;
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(e, fallback: 'No se pudieron cargar los usuarios'),
      );
    }
  }

  /// Crea la cuenta propia de un trabajador. Lanza el error de la API si falla.
  Future<AppUser> create({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final user = await _service.createUser(name: name, email: email, password: password, role: role);
    if (mounted) state = state.copyWith(users: [...state.users, user]);
    return user;
  }

  /// Activa o desactiva un usuario. Lanza el error de la API si falla.
  Future<void> setActive(AppUser user, bool active) async {
    final updated = await _service.updateUser(user.id, active: active);
    _replace(updated);
  }

  Future<void> changeRole(AppUser user, String role) async {
    final updated = await _service.updateUser(user.id, role: role);
    _replace(updated);
  }

  void _replace(AppUser updated) {
    if (!mounted) return;
    state = state.copyWith(
      users: [for (final u in state.users) if (u.id == updated.id) updated else u],
    );
  }
}

final usersProvider = StateNotifierProvider.autoDispose<UsersNotifier, UsersState>((ref) {
  return UsersNotifier(ref.read(userApiServiceProvider));
});
