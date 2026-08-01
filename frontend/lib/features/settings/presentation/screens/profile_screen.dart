import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_badge.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/features/profile/domain/entities/profile.dart';
import 'package:fiapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:fiapp/features/settings/presentation/screens/profile_screen_helpers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _businessController;
  late final TextEditingController _emailController;
  String? _syncedProfileId;

  @override
  void initState() {
    super.initState();
    _businessController = TextEditingController(text: 'Mi Tienda');
    _emailController = TextEditingController(text: 'mitienda@correo.com');
  }

  @override
  void dispose() {
    _businessController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  void _syncProfileData(Profile? profile) {
    if (profile == null) {
      if (_syncedProfileId != null) {
        _syncedProfileId = null;
        _businessController.text = 'Mi Tienda';
        _emailController.text = 'mitienda@correo.com';
      }
      return;
    }

    if (_syncedProfileId != profile.id) {
      _syncedProfileId = profile.id;
      _businessController.text = profile.nombreNegocio;
      _emailController.text = profile.email;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final profile = state.profile;
    _syncProfileData(profile);

    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: AppColors.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Mi perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                          color: AppColors.blue, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        profile != null && profile.nombreNegocio.isNotEmpty
                            ? profile.nombreNegocio
                                .substring(0, 2)
                                .toUpperCase()
                            : 'MT',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            fontFamily: 'Inter'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.nombreNegocio ?? 'Mi Tienda',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? 'mitienda@correo.com',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                                fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 8),
                          const AppBadge(
                              text: 'Plan gratuito', color: AppColors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Miembro desde',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontFamily: 'Inter'),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Ene 2025',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontFamily: 'Inter'),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Gratuito',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos del negocio',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      fontFamily: 'Inter',
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 16),
                ProfileField(
                    label: 'Nombre del negocio',
                    controller: _businessController),
                const SizedBox(height: 16),
                ProfileField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Guardar cambios',
            fullWidth: true,
            onPressed: _saveProfile,
          ),
        ],
      ),
    );
  }
}
