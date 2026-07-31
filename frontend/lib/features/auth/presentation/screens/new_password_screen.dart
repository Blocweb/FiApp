import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  String _password = '';
  String _confirmPassword = '';

  void _handleChangePassword() {
    if (_password.isEmpty || _confirmPassword.isEmpty) return;
    context.go('/login');
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.go('/verify-code'),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Nueva contraseña',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.lock_outline, size: 34, color: AppColors.green),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Crea tu nueva contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      'Elige una contraseña segura que no hayas usado antes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  child: Column(
                    children: [
                      AppInput(
                        label: 'Nueva contraseña',
                        value: _password,
                        onChanged: (value) => setState(() => _password = value),
                        obscureText: true,
                        placeholder: 'Mínimo 6 caracteres',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Confirmar contraseña',
                        value: _confirmPassword,
                        onChanged: (value) => setState(() => _confirmPassword = value),
                        obscureText: true,
                        placeholder: 'Repite tu contraseña',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  label: 'Cambiar contraseña',
                  variant: AppButtonVariant.green,
                  fullWidth: true,
                  onPressed: _handleChangePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
