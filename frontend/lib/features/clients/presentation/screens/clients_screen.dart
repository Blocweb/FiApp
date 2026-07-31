import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_avatar.dart';
import 'package:fiapp/core/widgets/app_badge.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_fab.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';

/// Pantalla de listado de clientes con buscador y botón flotante para
/// crear uno nuevo. Réplica de `ClientsScreen` del prototipo original.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider).clients;
    final filtered = clients.where((c) {
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.phone.contains(_query);
    }).toList();

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Column(
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
                      'Clientes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        hintText: 'Buscar cliente...',
                        prefixIcon: Icon(Icons.search, size: 18, color: AppColors.muted),
                        fillColor: AppColors.bg,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(query: _query)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 4),
                            child: Text(
                              '${filtered.length} ${filtered.length == 1 ? 'cliente' : 'clientes'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...filtered.map((client) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ClientTile(
                                  client: client,
                                  onTap: () => context.push('/client-detail', extra: client),
                                ),
                              )),
                        ],
                      ),
              ),
            ],
          ),
          AppFab(
            label: 'Nuevo cliente',
            onPressed: () => context.push('/new-client'),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDebt = client.balance > 0;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(client: client, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  client.lastMovement,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 5),
                AppBadge(
                  text: hasDebt ? 'Debe ${Formatters.currency(client.balance)}' : 'Al día ✓',
                  color: hasDebt ? AppColors.red : AppColors.green,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hasDebt ? AppColors.red : AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              'No se encontraron clientes',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontFamily: 'Inter', fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
