import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/pressable_scale.dart';

/// Variantes visuales del botón, equivalentes a las de `Btn` en React.
enum AppButtonVariant { primary, secondary, ghost, danger, green }

/// Botón reutilizable con variantes de color, ancho completo opcional,
/// ícono opcional y animación de presionado (equivalente a `Btn`).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool fullWidth;
  final Widget? icon;
  final bool disabled;
  final bool small;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
    this.disabled = false,
    this.small = false,
  });

  _ButtonColors get _colors {
    switch (variant) {
      case AppButtonVariant.primary:
        return const _ButtonColors(background: AppColors.blue, foreground: Colors.white);
      case AppButtonVariant.secondary:
        return const _ButtonColors(background: AppColors.blueLight, foreground: AppColors.blue);
      case AppButtonVariant.ghost:
        return const _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.blue,
          borderColor: AppColors.border,
        );
      case AppButtonVariant.danger:
        return const _ButtonColors(background: AppColors.redLight, foreground: AppColors.red);
      case AppButtonVariant.green:
        return const _ButtonColors(background: AppColors.green, foreground: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final isDisabled = disabled || onPressed == null;

    final content = Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 18 : 24,
        vertical: small ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: colors.borderColor != null
            ? Border.all(color: colors.borderColor!, width: 1.5)
            : null,
      ),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(color: colors.foreground, size: small ? 16 : 18),
                child: icon!,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.foreground,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: small ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return PressableScale(
      enabled: !isDisabled,
      onTap: isDisabled ? null : onPressed,
      child: content,
    );
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? borderColor;

  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.borderColor,
  });
}
