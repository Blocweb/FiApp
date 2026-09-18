import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/core/providers/repository_providers.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';

/// Estado de la lista de clientes de la tienda.
class ClientsState {
  final List<Client> clients;
  final bool isLoading;
  final String? error;

  const ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
  });

  ClientsState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? error,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controlador del estado global de clientes.
///
/// Equivale al `useState<Client[]>(INIT_CLIENTS)` del componente `App`
/// original, pero delegando el acceso a datos al repositorio.
class ClientsNotifier extends StateNotifier<ClientsState> {
  final Ref ref;

  ClientsNotifier(this.ref) : super(const ClientsState()) {
    loadClients();
  }

  Future<void> loadClients() async {
    if (!mounted) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(clientRepositoryProvider);
      final clients = await repo.getClients();
      if (!mounted) return;

      state = state.copyWith(clients: clients, isLoading: false);
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar los clientes',
      );
    }
  }

  Future<Client> addClient(Client client) async {
    final repo = ref.read(clientRepositoryProvider);
    final created = await repo.createClient(client);
    if (!mounted) return created;

    state = state.copyWith(clients: [created, ...state.clients]);
    return created;
  }

  Future<void> deleteClient(String clientId) async {
    final repo = ref.read(clientRepositoryProvider);
    await repo.deleteClient(clientId);
    if (!mounted) return;

    state = state.copyWith(
      clients: state.clients.where((c) => c.id != clientId).toList(),
    );
  }

  /// Refresca los datos de un cliente específico desde el backend.
  /// Usado típicamente después de registrar un fiado o abono para
  /// actualizar el saldo real calculado por el backend.
  Future<Client?> refreshClient(String clientId) async {
    final repo = ref.read(clientRepositoryProvider);
    final updated = await repo.getClientById(clientId);
    if (!mounted || updated == null) return updated;

    state = state.copyWith(
      clients: [
        for (final c in state.clients)
          if (c.id == clientId) updated else c,
      ],
    );
    return updated;
  }

  Client? findById(String id) {
    try {
      return state.clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

final clientsProvider =
    StateNotifierProvider<ClientsNotifier, ClientsState>((ref) {
  return ClientsNotifier(ref);
});
