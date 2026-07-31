import 'package:flutter/material.dart';

/// Paleta de colores de FiApp.
///
/// Replica exactamente los valores hexadecimales usados en el prototipo
/// original (objeto `P` de App.tsx) para conservar la identidad visual.
class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color blueLight = Color(0xFFEFF6FF);

  static const Color green = Color(0xFF22C55E);
  static const Color greenLight = Color(0xFFF0FDF4);
  static const Color greenDark = Color(0xFF16A34A);

  static const Color warn = Color(0xFFF59E0B);
  static const Color warnLight = Color(0xFFFFFBEB);

  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFEF2F2);

  static const Color bg = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);

  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  /// Colores disponibles para asignar como color identificador de un cliente
  /// (avatar). Igual al arreglo `colors` de NewClientScreen en el original.
  static const List<Color> clientPalette = [
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFF6366F1),
  ];
}
