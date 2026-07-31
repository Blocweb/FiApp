import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_animations.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';
import 'package:fiapp/core/widgets/app_logo_icon.dart';

/// Pantalla de inicio de sesión. Réplica de `LoginScreen` del prototipo
/// original: mismo layout, mismo flujo de "loading" simulado antes de
/// entrar a home.
///
/// Nota de integración futura: al conectar el backend en ASP.NET Core, el
/// método [_handleLogin] debe delegar en un `AuthRepository.login(email,
/// password)` en vez de simular con `Future.delayed`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    // Nota: reemplazar por llamada real a AuthRepository.login()
    // apuntando al futuro endpoint POST /api/auth/login de ASP.NET Core.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const AppLogoIcon(size: 34),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FiApp',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inicia sesión en tu cuenta',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    AppCard(
                      child: Column(
                        children: [
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
                            placeholder: '••••••••',
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(top: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: _loading ? 'Iniciando sesión...' : 'Ingresar',
                      fullWidth: true,
                      disabled: _loading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: TextStyle(color: AppColors.muted, fontSize: 13, fontFamily: 'Inter'),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Crear cuenta nueva',
                      fullWidth: true,
                      variant: AppButtonVariant.ghost,
                      onPressed: () => context.push('/register'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
