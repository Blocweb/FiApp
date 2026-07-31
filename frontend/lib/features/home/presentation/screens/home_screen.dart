import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_avatar.dart';
import 'package:fiapp/core/widgets/app_badge.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/pressable_scale.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';
import 'package:fiapp/features/history/presentation/providers/transactions_provider.dart';

/// Pantalla principal (Inicio). Réplica de `HomeScreen` del prototipo
/// original: header azul con saludo, tarjetas de estadísticas
/// superpuestas, acción rápida "Registrar nuevo fiado" y lista de
/// movimientos recientes.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsState = ref.watch(clientsProvider);
    final txState = ref.watch(transactionsProvider);

    final clients = clientsState.clients;
    final transactions = txState.transactions;

    final totalDebt = clients.fold<double>(0, (s, c) => s + c.balance);
    final debtors = clients.where((c) => c.balance > 0).length;
    final todayAbonos = transactions
        .where((t) => t.type == TransactionType.abono && t.date == 'Hoy')
        .fold<double>(0, (s, t) => s + t.amount);
    final recentTx = transactions.take(4).toList();

    Client? getClient(String id) {
      try {
        return clients.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    void goToFiado() {
      final client = clients.isNotEmpty ? clients.first : null;
      if (client != null) {
        context.push('/register-fiado', extra: client);
      }
    }

    void goToClientDetail(Client client) {
      context.push('/client-detail', extra: client);
    }

    return Container(
      color: AppColors.bg,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Header azul
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
                    decoration: const BoxDecoration(color: AppColors.blue),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -40,
                          right: -40,
                          child: _decorativeCircle(160),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -20,
                          child: _decorativeCircle(120),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenido 👋',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Mi tienda',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'MT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tarjetas superpuestas
                  Positioned(
                    top: 76,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Total por cobrar',
                                value: Formatters.currency(totalDebt),
                                badgeText: 'Pendiente',
                                badgeColor: AppColors.warn,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Clientes',
                                value: '${clients.length}',
                                badgeText: '$debtors con deuda',
                                badgeColor: AppColors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Cobros hoy',
                                value: Formatters.currency(todayAbonos),
                                valueColor: AppColors.green,
                                badgeText: 'Recibido',
                                badgeColor: AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Deudas activas',
                                value: '$debtors',
                                badgeText: 'Por cobrar',
                                badgeColor: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Acción rápida
                PressableScale(
                  onTap: goToFiado,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar nuevo fiado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                'En menos de 30 segundos',
                                style: TextStyle(
                                  color: Color(0xB3FFFFFF),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Movimientos recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 10),
                ...recentTx.map((tx) {
                  final client = getClient(tx.clientId);
                  if (client == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => goToClientDetail(client),
                      child: Row(
                        children: [
                          AppAvatar(client: client, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${tx.isFiado ? '📋 Fiado registrado' : '💵 Abono recibido'} · ${tx.date}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.isFiado ? '+' : '-'}${Formatters.currency(tx.amount)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tx.isFiado ? AppColors.red : AppColors.green,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String badgeText;
  final Color badgeColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor,
    required this.badgeText,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              fontFamily: 'Inter',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.ink,
              fontFamily: 'Inter',
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          AppBadge(text: badgeText, color: badgeColor),
        ],
      ),
    );
  }
}
