import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/features/reportes/domain/entities/reporte.dart';
import 'package:fiapp/features/reportes/presentation/providers/reportes_provider.dart';


class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
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
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportesProvider);
    final resumen = state.resumen;
    final evolucion = state.evolucion;

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
              if (state.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.muted, size: 20),
                  onPressed: () => ref.read(reportesProvider.notifier).load(),
                  tooltip: 'Actualizar',
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Error banner
          if (state.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(fontSize: 13, color: AppColors.red, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ),

          // Stats cards
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCard(
                      'Total por cobrar',
                      resumen != null ? Formatters.currency(resumen.totalPorCobrar) : '—',
                      resumen != null ? '${resumen.clientesConDeuda} clientes' : '—',
                      AppColors.red,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Cobros hoy',
                      resumen != null ? Formatters.currency(resumen.cobrosHoy) : '—',
                      'Abonos del día',
                      AppColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCard(
                      'Total clientes',
                      resumen != null ? '${resumen.totalClientes}' : '—',
                      'Activos',
                      AppColors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Con deuda activa',
                      resumen != null ? '${resumen.clientesConDeuda}' : '—',
                      'Saldo > 0',
                      AppColors.warn,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Evolución mensual
          if (evolucion.isNotEmpty) ...[
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
                  _EvolucionChart(evolucion: evolucion),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        CircleAvatar(radius: 5, backgroundColor: AppColors.red),
                        SizedBox(width: 6),
                        Text('Fiado', style: TextStyle(fontSize: 12, color: AppColors.red, fontFamily: 'Inter')),
                      ]),
                      Row(children: [
                        CircleAvatar(radius: 5, backgroundColor: AppColors.green),
                        SizedBox(width: 6),
                        Text('Abono', style: TextStyle(fontSize: 12, color: AppColors.green, fontFamily: 'Inter')),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Resumen de clientes
          if (resumen != null)
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
                      _buildSummaryValue('Total de clientes', '${resumen.totalClientes}'),
                      const SizedBox(width: 14),
                      _buildSummaryValue('Con deuda activa', '${resumen.clientesConDeuda}'),
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

/// Widget interno para renderizar el gráfico de barras de evolución.
class _EvolucionChart extends StatelessWidget {
  final List<EvolucionMensual> evolucion;

  const _EvolucionChart({required this.evolucion});

  @override
  Widget build(BuildContext context) {
    // Tomamos los últimos 6 meses
    final items = evolucion.length > 6 ? evolucion.sublist(evolucion.length - 6) : evolucion;
    final maxVal = items.fold<double>(1, (prev, e) {
      final m = e.totalFiado > e.totalAbono ? e.totalFiado : e.totalAbono;
      return m > prev ? m : prev;
    });

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items.expand((e) {
              final fiadoH = maxVal > 0 ? (e.totalFiado / maxVal) * 100 : 0.0;
              final abonoH = maxVal > 0 ? (e.totalAbono / maxVal) * 100 : 0.0;
              return [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: fiadoH,
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: abonoH,
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.shortMonth(e.mes),
                        style: const TextStyle(fontSize: 10, color: AppColors.muted, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ];
            }).toList(),
          ),
        ),
      ],
    );
  }
}
