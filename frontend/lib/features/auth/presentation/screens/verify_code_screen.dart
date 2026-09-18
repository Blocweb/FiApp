import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fiapp/core/router/app_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';

/// Pantalla de verificación de código OTP o enlace de correo.
///
/// Permite al usuario verificar el código numérico recibido por correo
/// mediante [Supabase.auth.verifyOTP] con tipo [OtpType.recovery], o esperar
/// la redirección si hace clic directamente en el enlace del correo.
class VerifyCodeScreen extends StatefulWidget {
  final String? email;

  const VerifyCodeScreen({super.key, this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final TextEditingController _emailFallbackController;
  late String _email;

  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = widget.email ?? '';
    _emailFallbackController = TextEditingController(text: _email);
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _emailFallbackController.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerify() async {
    final effectiveEmail = _email.isNotEmpty ? _email : _emailFallbackController.text.trim();
    if (effectiveEmail.isEmpty) {
      setState(() => _error = 'Ingresa el correo electrónico para verificar.');
      return;
    }

    final code = _otpCode;
    if (code.length < 6) {
      setState(() => _error = 'Ingresa el código completo de 6 dígitos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: effectiveEmail,
        token: code,
        type: OtpType.recovery,
      );

      if (!mounted) return;

      if (response.session != null) {
        context.go(AppRoutes.newPassword);
      } else {
        setState(() {
          _error = 'No se pudo validar el código. Verifica e intenta de nuevo.';
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ocurrió un error inesperado al verificar.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResend() async {
    final effectiveEmail = _email.isNotEmpty ? _email : _emailFallbackController.text.trim();
    if (effectiveEmail.isEmpty) {
      setState(() => _error = 'Ingresa tu correo para reenviar el código.');
      return;
    }

    setState(() => _isResending = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(effectiveEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nuevo código enviado a tu correo.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reenviar el código.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Widget _buildDigitField(int index) {
    return SizedBox(
      width: 46,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.card,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (_error != null) setState(() => _error = null);
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_otpCode.length == 6) {
            _handleVerify();
          }
        },
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.go(AppRoutes.forgotPassword),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Verifica tu correo',
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
              const SizedBox(height: 24),
              Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.mark_email_unread_outlined, size: 34, color: AppColors.blue),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Revisa tu bandeja de entrada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      _email.isNotEmpty
                          ? 'Enviamos un enlace y un código de 6 dígitos a:\n$_email'
                          : 'Enviamos un enlace y un código de 6 dígitos a tu correo.',
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
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ingresa el código de 6 dígitos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) => _buildDigitField(index)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
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
                  label: _isLoading ? 'Verificando...' : 'Verificar código',
                  fullWidth: true,
                  onPressed: _isLoading ? () {} : _handleVerify,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isResending ? null : _handleResend,
                  child: Text(
                    _isResending ? 'Reenviando...' : '¿No recibiste el código? Reenviar',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Volver al inicio de sesión',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
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

