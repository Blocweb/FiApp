import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fiapp/core/router/app_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Ingresa tu correo electrónico.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _isLoading = false;
      });
      // Navegar a la pantalla de verificación pasando el email
      context.go(AppRoutes.verifyCode, extra: email);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ocurrió un error inesperado. Intenta de nuevo.';
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
                        onTap: () => context.go('/login'),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_ios_new,
                              size: 18, color: AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recuperar contraseña',
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
                      color: _sent ? AppColors.greenLight : AppColors.blueLight,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _sent
                          ? Icons.mark_email_read_outlined
                          : Icons.email_outlined,
                      size: 34,
                      color: _sent ? AppColors.green : AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _sent ? '¡Correo enviado!' : '¿Olvidaste tu contraseña?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      _sent
                          ? 'Revisa tu bandeja de entrada. Haz clic en el enlace del correo para restablecer tu contraseña.'
                          : 'Ingresa tu correo y te enviaremos un enlace para recuperar tu cuenta.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
              if (!_sent) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    child: Column(
                      children: [
                        AppInput(
                          label: 'Correo electrónico',
                          value: _emailController.text,
                          onChanged: (value) {
                            _emailController.text = value;
                            if (_error != null) setState(() => _error = null);
                          },
                          keyboardType: TextInputType.emailAddress,
                          placeholder: 'tu@correo.com',
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
                    label: _isLoading ? 'Enviando...' : 'Enviar enlace',
                    fullWidth: true,
                    onPressed: _isLoading ? () {} : _handleSendEmail,
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
                    label: 'Reenviar enlace',
                    fullWidth: true,
                    onPressed: () => setState(() => _sent = false),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Volver al inicio de sesión',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
