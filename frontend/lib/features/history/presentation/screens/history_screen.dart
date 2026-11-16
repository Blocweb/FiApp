import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';
import 'package:fiapp/features/history/presentation/providers/transactions_provider.dart';

enum _HistoryFilter { all, fiado, abono }

/// Pantalla de historial de movimientos con filtros (Todos/Fiados/Abonos),
/// búsqueda por nombre de cliente y agrupación por fecha. Réplica de
/// `HistoryScreen` del prototipo original.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider).transactions;
    final clients = ref.watch(clientsProvider).clients;

    Client? getClient(String id) {
      try {
        return clients.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    final filtered = transactions.where((tx) {
      final client = getClient(tx.clientId);
      final matchType = _filter == _HistoryFilter.all ||
          (_filter == _HistoryFilter.fiado && tx.isFiado) ||
          (_filter == _HistoryFilter.abono && !tx.isFiado);
      final matchSearch = _search.isEmpty ||
          (client?.name.toLowerCase().contains(_search.toLowerCase()) ?? false);
      return matchType && matchSearch;
    }).toList();

    final groups = <String, List<Transaction>>{};
    for (final tx in filtered) {
      groups.putIfAbsent(tx.date, () => []).add(tx);
    }

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
                  decoration: const InputDecoration(
                    hintText: 'Buscar cliente...',
                    prefixIcon: Icon(Icons.search, size: 16, color: AppColors.muted),
                    fillColor: AppColors.bg,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      selected: _filter == _HistoryFilter.all,
                      onTap: () => setState(() => _filter = _HistoryFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Fiados',
                      selected: _filter == _HistoryFilter.fiado,
                      onTap: () => setState(() => _filter = _HistoryFilter.fiado),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Abonos',
                      selected: _filter == _HistoryFilter.abono,
                      onTap: () => setState(() => _filter = _HistoryFilter.abono),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📭', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 10),
                        Text(
                          'Sin movimientos',
                          style: TextStyle(color: AppColors.muted, fontFamily: 'Inter', fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: groups.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                                fontFamily: 'Inter',
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...entry.value.map((tx) {
                              final client = getClient(tx.clientId);
                              if (client == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _HistoryTile(tx: tx, client: client),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueLight : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.blue : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.blue : AppColors.muted,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Transaction tx;
  final Client client;

  const _HistoryTile({required this.tx, required this.client});

  @override
  Widget build(BuildContext context) {
    final extra = [
      if (tx.items != null) '${tx.items!.length} prod.',
      if (tx.paymentMethod != null) tx.paymentMethod!,
      if (tx.registeredByName != null) 'Por ${tx.registeredByName}',
    ].join(' · ');

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tx.isFiado ? AppColors.redLight : AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              tx.isFiado ? Icons.add : Icons.check,
              size: 16,
              color: tx.isFiado ? AppColors.red : AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.isFiado ? 'Fiado' : 'Abono'} · ${tx.time}${extra.isNotEmpty ? ' · $extra' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
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
    );
  }
}
