import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_card.dart';

/// Pantalla de exportación de información.
///
/// La funcionalidad de descarga de archivos (Excel / PDF) está planificada
/// para una versión futura. Actualmente muestra un aviso "Próximamente".
class ExportInfoScreen extends StatelessWidget {
  const ExportInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // Header
          Row(
            children: [
              Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go('/settings'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Exportar información',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Próximamente card
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.upload_file_rounded, size: 40, color: AppColors.blue),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Próximamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'La exportación de tus datos a Excel y PDF estará disponible en una versión próxima de FiApp.\n\nSeguimos trabajando para ti. 🚀',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                    fontFamily: 'Inter',
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(
                      child: _FeaturePill(icon: Icons.grid_on, label: 'Excel (.xlsx)', color: AppColors.blue),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _FeaturePill(icon: Icons.picture_as_pdf, label: 'PDF', color: AppColors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
