import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  bool get _hasMinLength => _newPassword.length >= 6;

  bool get _hasLettersAndNumbers {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(_newPassword);
  }

  bool get _isDifferent => _newPassword.isNotEmpty && _newPassword != _currentPassword;

  bool get _canUpdate {
    return _currentPassword.isNotEmpty &&
        _hasMinLength &&
        _hasLettersAndNumbers &&
        _isDifferent &&
        _newPassword == _confirmPassword;
  }

  void _handleUpdatePassword() {
    if (!_canUpdate) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Por favor completa los datos correctamente.'),
            backgroundColor: AppColors.warn,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  Widget _buildRequirement(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: valid ? AppColors.green : AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: valid
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: valid ? AppColors.ink : AppColors.muted,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Cambiar contraseña',
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  backgroundColor: AppColors.blueLight,
                  border: Border.all(color: AppColors.blueLight),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.lock_outline, size: 22, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Por seguridad, te pedimos confirmar tu contraseña actual antes de establecer una nueva.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.ink,
                                fontFamily: 'Inter',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppInput(
                        label: 'Contraseña actual',
                        value: _currentPassword,
                        onChanged: (value) => setState(() => _currentPassword = value),
                        obscureText: true,
                        placeholder: 'Tu contraseña actual',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Nueva contraseña',
                        value: _newPassword,
                        onChanged: (value) => setState(() => _newPassword = value),
                        obscureText: true,
                        placeholder: 'Mínimo 6 caracteres',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Confirmar nueva contraseña',
                        value: _confirmPassword,
                        onChanged: (value) => setState(() => _confirmPassword = value),
                        obscureText: true,
                        placeholder: 'Repite la nueva contraseña',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  noShadow: true,
                  backgroundColor: AppColors.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'La contraseña debe tener:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                          fontFamily: 'Inter',
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildRequirement('Al menos 6 caracteres', _hasMinLength),
                      _buildRequirement('Letras y números', _hasLettersAndNumbers),
                      _buildRequirement('Diferente a la anterior', _isDifferent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  label: 'Actualizar contraseña',
                  variant: AppButtonVariant.green,
                  fullWidth: true,
                  onPressed: _handleUpdatePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
