import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fiapp/core/debug/session_debug_log.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_repository_provider.dart';

class ProfileState {
  static const Object _unset = Object();

  final Profile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    Object? profile = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return ProfileState(
      profile: identical(profile, _unset) ? this.profile : profile as Profile?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (!mounted) return;

    logSupabaseSessionSnapshot('profileProvider.loadProfile.start');
    state = state.copyWith(profile: null, isLoading: true, error: null);
    try {
      final profile = await _repository.getProfile();
      if (!mounted) return;

      final currentUser = Supabase.instance.client.auth.currentUser;
      logSupabaseSessionSnapshot(
        'profileProvider.loadProfile.success',
        extra: {
          'profile.id': profile.id,
          'profile.email': profile.email,
        },
      );
      if (kDebugMode && currentUser != null && profile.id != currentUser.id) {
        debugPrint(
          '[TEMP AUTH DEBUG][MISMATCH] profile.id=${profile.id} '
          'currentUser.id=${currentUser.id}',
        );
      }
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (error) {
      logSupabaseSessionSnapshot(
        'profileProvider.loadProfile.error',
        extra: {'error': error},
      );
      if (!mounted) return;

      state = state.copyWith(
        profile: null,
        isLoading: false,
        error: 'No se pudo cargar el perfil. Intenta de nuevo.',
      );
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return ProfileNotifier(repository);
});
