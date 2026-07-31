import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_animations.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/illustrations/illustration_coins.dart';
import 'package:fiapp/core/widgets/illustrations/illustration_notebook.dart';
import 'package:fiapp/core/widgets/illustrations/illustration_search.dart';

class _OnboardSlide {
  final String title;
  final String subtitle;
  final Widget illustration;

  const _OnboardSlide({
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}

/// Pantalla de onboarding con 3 slides informativos, igual que
/// `OnboardingScreen` en el prototipo original, incluyendo la animación
/// de fade al cambiar de slide y los indicadores de progreso.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  static const _slides = [
    _OnboardSlide(
      title: 'Nunca pierdas un fiado.',
      subtitle:
          'Olvídate del cuaderno. Registra deudas en segundos desde tu celular.',
      illustration: IllustrationNotebook(),
    ),
    _OnboardSlide(
      title: 'Encuentra cualquier deuda en segundos.',
      subtitle:
          'Busca clientes por nombre y consulta su historial completo al instante.',
      illustration: IllustrationSearch(),
    ),
    _OnboardSlide(
      title: 'Controla tus cobros fácilmente.',
      subtitle:
          'Registra abonos, lleva el historial y siempre sabe quién te debe cuánto.',
      illustration: IllustrationCoins(),
    ),
  ];

  void _finish() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_step];
    final isLast = _step == _slides.length - 1;

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: AppAnimations.fadeIn,
              switchInCurve: AppAnimations.fadeInCurve,
              switchOutCurve: AppAnimations.fadeInCurve,
              child: Padding(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: slide.illustration),
                    const SizedBox(height: 32),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFamily: 'Inter',
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slide.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.muted,
                        fontFamily: 'Inter',
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppColors.blue : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                if (!isLast)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _finish,
                          child: const Text(
                            'Omitir',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: 'Siguiente →',
                          fullWidth: true,
                          onPressed: () => setState(() => _step++),
                        ),
                      ),
                    ],
                  )
                else
                  AppButton(label: 'Comenzar', fullWidth: true, onPressed: _finish),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
