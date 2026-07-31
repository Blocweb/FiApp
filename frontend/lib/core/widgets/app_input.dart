import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';

/// Campo de texto con etiqueta encima, replicando el componente `Input`
/// del prototipo original (incluye soporte para texto multilínea).
class AppInput extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? placeholder;
  final bool multiline;

  const AppInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.placeholder,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: multiline ? TextInputType.multiline : keyboardType,
          obscureText: obscureText,
          maxLines: multiline ? 3 : 1,
          minLines: multiline ? 3 : 1,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Inter',
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
          ),
        ),
      ],
    );
  }
}
