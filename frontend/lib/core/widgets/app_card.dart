import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/pressable_scale.dart';

/// Tarjeta blanca con esquinas redondeadas y sombra sutil, equivalente al
/// componente `Card` de React. Si se provee [onTap], obtiene la animación
/// de presionado.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Border? border;
  final bool noShadow;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.border,
    this.noShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: noShadow
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    final cardMaterial = Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: card,
    );

    if (onTap == null) return cardMaterial;

    return PressableScale(onTap: onTap, child: cardMaterial);
  }
}
