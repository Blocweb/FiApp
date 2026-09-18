import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';

/// Pantalla de nueva contraseña.
///
/// Supabase envía un enlace de recuperación al correo del usuario. Al hacer
/// clic en ese enlace, la app recibe un deep-link con un token de sesión
/// que Supabase maneja automáticamente. Esta pantalla permite al usuario
/// definir su nueva contraseña usando [Supabase.auth.updateUser].
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Completa ambos campos.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (!mounted) return;
      // Redirigir al home después de cambiar la contraseña exitosamente.
      context.go('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error inesperado. Intenta de nuevo.';
        _isLoading = false;
      });
    }
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
                        onTap: () => context.go('/forgot-password'),
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
                        value: _passwordController.text,
                        onChanged: (value) {
                          _passwordController.text = value;
                          if (_error != null) setState(() => _error = null);
                        },
                        obscureText: true,
                        placeholder: 'Mínimo 6 caracteres',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Confirmar contraseña',
                        value: _confirmController.text,
                        onChanged: (value) {
                          _confirmController.text = value;
                          if (_error != null) setState(() => _error = null);
                        },
                        obscureText: true,
                        placeholder: 'Repite tu contraseña',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.red,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  label: _isLoading ? 'Guardando...' : 'Cambiar contraseña',
                  variant: AppButtonVariant.green,
                  fullWidth: true,
                  onPressed: _isLoading ? () {} : _handleChangePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
