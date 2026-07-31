import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';

/// Barra superior personalizada con botón de retroceso opcional y
/// contenido a la derecha, equivalente a `TopBar` del prototipo original.
class AppTopBar extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool transparent;

  const AppTopBar({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        decoration: BoxDecoration(
          color: transparent ? Colors.transparent : AppColors.card,
          border: transparent
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
        ),
        child: Row(
          children: [
            if (onBack != null) ...[
              _BackButton(onTap: onBack!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
        ),
      ),
    );
  }
}
