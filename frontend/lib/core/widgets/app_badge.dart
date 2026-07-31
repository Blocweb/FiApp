import 'package:flutter/material.dart';

/// Insignia de texto con fondo semitransparente del color indicado.
/// Equivalente al componente `Badge` de React.
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;

  const AppBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.094),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
