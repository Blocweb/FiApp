import 'package:flutter/material.dart';

/// Duraciones y curvas de animación de FiApp.
///
/// Cada constante corresponde a una animación `@keyframes` del CSS original
/// (index.css) para que las transiciones se sientan idénticas al prototipo.
class AppAnimations {
  AppAnimations._();

  // fadeIn: 0.35s ease
  static const Duration fadeIn = Duration(milliseconds: 350);
  static const Curve fadeInCurve = Curves.ease;

  // slideUp: 0.4s ease (translateY 20px -> 0, opacity 0 -> 1)
  static const Duration slideUp = Duration(milliseconds: 400);
  static const Curve slideUpCurve = Curves.ease;

  // slideInRight / slideInLeft: 0.3s cubic-bezier(0.4, 0, 0.2, 1)
  static const Duration slideHorizontal = Duration(milliseconds: 300);
  static const Curve slideHorizontalCurve = Cubic(0.4, 0, 0.2, 1);

  // scaleIn: 0.3s ease (scale 0.85 -> 1)
  static const Duration scaleIn = Duration(milliseconds: 300);
  static const Curve scaleInCurve = Curves.ease;

  // successPop: 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) — overshoot "pop"
  static const Duration successPop = Duration(milliseconds: 500);
  static const Curve successPopCurve = Cubic(0.34, 1.56, 0.64, 1);

  // logoReveal: 0.9s cubic-bezier(0.34, 1.56, 0.64, 1)
  static const Duration logoReveal = Duration(milliseconds: 900);
  static const Curve logoRevealCurve = Cubic(0.34, 1.56, 0.64, 1);

  // pressed: 0.1s ease (scale 0.97, opacity 0.85) al presionar botones/cards
  static const Duration pressed = Duration(milliseconds: 100);
  static const Curve pressedCurve = Curves.ease;

  // Splash auto-avanza tras 2.2s
  static const Duration splashDelay = Duration(milliseconds: 2200);
}
