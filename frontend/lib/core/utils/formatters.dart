import 'dart:math';
import 'package:intl/intl.dart';

/// Funciones auxiliares de formato, replicando los `helpers` del prototipo
/// original (fmt, initials, uid, now).
class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.decimalPattern('es_CO');

  /// Formatea un número como moneda colombiana: `$47.500`.
  static String currency(num value) {
    return '\$${_currencyFormat.format(value)}';
  }

  /// Obtiene las iniciales (máximo 2 letras) de un nombre completo.
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final firstTwo = parts.take(2);
    final letters = firstTwo
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();
    return letters;
  }

  /// Genera un identificador corto pseudo-aleatorio (similar a `uid()` en JS).
  static String uid() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(7, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Devuelve la hora actual en formato `HH:mm`.
  static String nowTime() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Devuelve la hora actual en formato 12h con AM/PM, para la status bar.
  static String nowTime12h() {
    final now = DateTime.now();
    final h = now.hour;
    final displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final mm = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    return '$displayHour:$mm $period';
  }

  /// Convierte una fecha a un formato "hace X tiempo"
  static String timeAgo(DateTime? date) {
    if (date == null) return 'Sin movimientos';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return 'Hace ${diff.inDays ~/ 365} años';
    if (diff.inDays > 30) return 'Hace ${diff.inDays ~/ 30} meses';
    if (diff.inDays > 0) return 'Hace ${diff.inDays} días';
    if (diff.inHours > 0) return 'Hace ${diff.inHours} horas';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes} minutos';
    return 'Hace un momento';
  }

  static const List<String> _shortMonths = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Formatea mes y año en español sin dependencias de localización (ej. "oct 2023").
  static String monthYear(DateTime? date) {
    if (date == null) return 'Sin datos';
    final m = _shortMonths[date.month - 1];
    return '$m ${date.year}';
  }

  /// Formatea mes abreviado con mayúscula inicial (ej. "Ene", "Feb").
  static String shortMonth(DateTime date) {
    final m = _shortMonths[date.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)}';
  }
}
