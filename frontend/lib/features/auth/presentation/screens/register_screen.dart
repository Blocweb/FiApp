import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_animations.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';
import 'package:fiapp/core/widgets/app_top_bar.dart';

/// Pantalla de creación de cuenta. Réplica de `RegisterScreen` del
/// prototipo original.
///
/// Nota de integración futura: [_handleRegister] debe llamar a
/// `AuthRepository.register(...)` contra el futuro endpoint
/// `POST /api/auth/register` de ASP.NET Core.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          AppTopBar(title: 'Crear cuenta', onBack: () => context.pop()),
          Expanded(
            child: SingleChildScrollView(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppAnimations.slideUp,
                curve: AppAnimations.slideUpCurve,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 20),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            AppInput(
                              label: 'Nombre completo',
                              value: _nameController.text,
                              onChanged: (v) => _nameController.text = v,
                              placeholder: 'Tu nombre',
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Correo electrónico',
                              value: _emailController.text,
                              onChanged: (v) => _emailController.text = v,
                              keyboardType: TextInputType.emailAddress,
                              placeholder: 'tu@correo.com',
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Contraseña',
                              value: _passController.text,
                              onChanged: (v) => _passController.text = v,
                              obscureText: true,
                              placeholder: 'Mínimo 8 caracteres',
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Confirmar contraseña',
                              value: _confirmController.text,
                              onChanged: (v) => _confirmController.text = v,
                              obscureText: true,
                              placeholder: 'Repite tu contraseña',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: _loading ? 'Creando cuenta...' : 'Crear cuenta',
                        fullWidth: true,
                        disabled: _loading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Al crear tu cuenta aceptas nuestros Términos y Condiciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
