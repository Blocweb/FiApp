import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_card.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String _activeRange = 'Mes';

  Widget _buildStatCard(String title, String amount, String subtitle, Color amountColor) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: amountColor,
                fontFamily: 'Inter',
              ),
            ),
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
        ),
      ),
    );
  }

  Widget _buildRangeButton(String label) {
    final selected = label == _activeRange;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeRange = label),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: selected ? AppColors.card : AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.blue : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.blue : AppColors.muted,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartBar({required double height, required Color color}) {
    return Flexible(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
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
                  onTap: () => Navigator.of(context).pop(),
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
                  'Reportes',
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
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildRangeButton('Semana'),
                    const SizedBox(width: 10),
                    _buildRangeButton('Mes'),
                    const SizedBox(width: 10),
                    _buildRangeButton('Total'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCard('Total fiado', ' 150.000', '5 fiados', AppColors.red),
                    const SizedBox(width: 12),
                    _buildStatCard('Total cobrado', ' 110.000', '3 abonos', AppColors.green),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCard('Por cobrar', ' 255.500', '4 clientes', AppColors.warn),
                    const SizedBox(width: 12),
                    _buildStatCard('Efectividad', '73%', 'Cobros vs fiados', AppColors.blue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Evolución mensual',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildChartBar(height: 70, color: AppColors.red.withOpacity(0.8))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildChartBar(height: 110, color: AppColors.green.withOpacity(0.8))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildChartBar(height: 90, color: AppColors.red.withOpacity(0.5))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildChartBar(height: 120, color: AppColors.green.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Fiado', style: TextStyle(fontSize: 12, color: AppColors.red, fontFamily: 'Inter')),
                    Text('Abono', style: TextStyle(fontSize: 12, color: AppColors.green, fontFamily: 'Inter')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Mayores deudas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                _buildDebtItem(1, 'Ana Martínez', ' 125.000', AppColors.red),
                const SizedBox(height: 12),
                _buildDebtItem(2, 'Jorge Moreno', ' 65.000', AppColors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de clientes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildSummaryValue('Total de clientes', '6'),
                    const SizedBox(width: 14),
                    _buildSummaryValue('Con deuda activa', '4'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtItem(int rank, String name, String amount, Color lineColor) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue, fontFamily: 'Inter'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, fontFamily: 'Inter'),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          amount,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red, fontFamily: 'Inter'),
        ),
      ],
    );
  }

  Widget _buildSummaryValue(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}
