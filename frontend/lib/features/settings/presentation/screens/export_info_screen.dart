import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';

class ExportInfoScreen extends StatefulWidget {
  const ExportInfoScreen({super.key});

  @override
  State<ExportInfoScreen> createState() => _ExportInfoScreenState();
}

class _ExportInfoScreenState extends State<ExportInfoScreen> {
  String _selectedFormat = 'excel';
  String _selectedScope = 'all';
  bool _submitted = false;

  void _selectFormat(String format) {
    setState(() {
      _selectedFormat = format;
    });
  }

  void _selectScope(String scope) {
    setState(() {
      _selectedScope = scope;
    });
  }

  void _handleExport() {
    setState(() {
      _submitted = true;
    });
  }

  void _handleExportAgain() {
    setState(() {
      _submitted = false;
    });
  }

  Widget _buildSelectableCard({
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
    Widget? icon,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      backgroundColor: selected ? AppColors.blueLight : AppColors.card,
      border: Border.all(color: selected ? AppColors.blue : AppColors.border),
      child: Row(
        children: [
          if (icon != null) icon,
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.blue : AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.blue : AppColors.muted,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        backgroundColor: AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
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
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de datos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    fontFamily: 'Inter',
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildSummaryTile('Clientes', '6'),
                    const SizedBox(width: 12),
                    _buildSummaryTile('Con deuda', '4'),
                    const SizedBox(width: 12),
                    _buildSummaryTile('Movimientos', '8'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'FORMATO DE EXPORTACIÓN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    fontFamily: 'Inter',
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSelectableCard(
                  title: 'Excel (.xlsx)',
                  subtitle: 'Compatible con Microsoft Excel y Google Sheets',
                  selected: _selectedFormat == 'excel',
                  icon: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.grid_on, color: AppColors.blue),
                  ),
                  onTap: () => _selectFormat('excel'),
                ),
                const SizedBox(height: 12),
                _buildSelectableCard(
                  title: 'PDF',
                  subtitle: 'Ideal para imprimir o enviar por WhatsApp',
                  selected: _selectedFormat == 'pdf',
                  icon: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.picture_as_pdf, color: AppColors.red),
                  ),
                  onTap: () => _selectFormat('pdf'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '¿QUÉ EXPORTAR?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    fontFamily: 'Inter',
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSelectableCard(
                  title: 'Todos los clientes',
                  subtitle: '6 registros',
                  selected: _selectedScope == 'all',
                  onTap: () => _selectScope('all'),
                ),
                const SizedBox(height: 12),
                _buildSelectableCard(
                  title: 'Solo clientes con deuda',
                  subtitle: '4 registros',
                  selected: _selectedScope == 'debt',
                  onTap: () => _selectScope('debt'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_submitted)
            AppButton(
              label: 'Exportar ${_selectedFormat == 'excel' ? 'Excel (.xlsx)' : 'PDF'}',
              fullWidth: true,
              onPressed: _handleExport,
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.download_done, size: 32, color: AppColors.green),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '¡Exportación lista!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tu archivo ${_selectedFormat == 'excel' ? 'Excel (.xlsx)' : 'PDF'} con ${_selectedScope == 'all' ? '6 registros' : '4 registros'} está listo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      fontFamily: 'Inter',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Descargar archivo',
                    fullWidth: true,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _handleExportAgain,
                      child: const Text(
                        'Exportar de nuevo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
