import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_badge.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';
import 'package:fiapp/features/history/presentation/providers/transactions_provider.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';

/// Pantalla de detalle de un cliente: header azul con saldo, acciones
/// rápidas (Fiado / Abono), dirección, notas e historial en formato
/// línea de tiempo. Réplica de `ClientDetailScreen` del prototipo
/// original.
class ClientDetailScreen extends ConsumerWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTx = ref.watch(transactionsProvider).transactions;
    final clientTx = allTx.where((t) => t.clientId == client.id).take(10).toList();

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            color: AppColors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        onTap: () async {
                          if (client.balance > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No se puede eliminar a ${client.name} porque tiene una deuda activa de ${Formatters.currency(client.balance)}.',
                                  style: const TextStyle(fontFamily: 'Inter'),
                                ),
                                backgroundColor: AppColors.red,
                              ),
                            );
                            return;
                          }

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar cliente', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                              content: Text(
                                '¿Estás seguro de eliminar a ${client.name}? Esta acción no se puede deshacer.',
                                style: const TextStyle(fontFamily: 'Inter'),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(clientsProvider.notifier).deleteClient(client.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
                                context.pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al eliminar: $e'),
                                    backgroundColor: AppColors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Color(client.color).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Formatters.initials(client.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (client.phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📞 ${client.phone}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALDO PENDIENTE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(client.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Fiado',
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => context.push('/register-fiado', extra: client),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Abono',
                        variant: AppButtonVariant.green,
                        icon: const Icon(Icons.check, size: 16),
                        onPressed: () => context.push('/register-abono', extra: client),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (client.address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              client.address,
                              style: const TextStyle(fontSize: 14, color: AppColors.muted, fontFamily: 'Inter', height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (client.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.description_outlined, size: 16, color: AppColors.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              client.notes,
                              style: const TextStyle(fontSize: 14, color: AppColors.muted, fontFamily: 'Inter', height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Historial',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'Inter'),
                  ),
                ),
                const SizedBox(height: 10),
                if (clientTx.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text('📋', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'Sin movimientos registrados',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(clientTx.length, (i) {
                    final tx = clientTx[i];
                    final isLast = i == clientTx.length - 1;
                    return _TimelineItem(tx: tx, isLast: isLast);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Transaction tx;
  final bool isLast;

  const _TimelineItem({required this.tx, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tx.isFiado ? AppColors.redLight : AppColors.greenLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  tx.isFiado ? Icons.add : Icons.check,
                  size: 14,
                  color: tx.isFiado ? AppColors.red : AppColors.green,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.isFiado ? 'Fiado registrado' : 'Abono recibido',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.date} · ${tx.time}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${tx.isFiado ? '+' : '-'}${Formatters.currency(tx.amount)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tx.isFiado ? AppColors.red : AppColors.green,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saldo: ${Formatters.currency(tx.balanceAfter)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (tx.items != null && tx.items!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: tx.items!.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.qty}× ${item.name}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
                                ),
                                Text(
                                  Formatters.currency(item.subtotal),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink, fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (tx.paymentMethod != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AppBadge(text: tx.paymentMethod!, color: AppColors.green),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
