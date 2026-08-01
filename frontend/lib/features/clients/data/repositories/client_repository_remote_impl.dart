import 'package:fiapp/features/clients/data/models/client_model.dart';
import 'package:fiapp/features/clients/data/services/client_api_service.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/domain/repositories/client_repository.dart';

class ClientRepositoryRemoteImpl implements ClientRepository {
  final ClientApiService _service;

  ClientRepositoryRemoteImpl([ClientApiService? service]) : _service = service ?? ClientApiService();

  @override
  Future<Client> createClient(Client client) async {
    final payload = ClientModel.fromEntity(client).toJson();
    final created = await _service.createClient(payload);
    return created;
  }

  @override
  Future<Client?> getClientById(String id) async {
    // API currently exposes GET /clientes and GET /clientes/{id} not implemented in service
    final all = await _service.getClients();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Client>> getClients() async {
    final list = await _service.getClients();
    return list;
  }

  @override
  Future<Client> updateClient(Client client) async {
    final payload = ClientModel.fromEntity(client).toJson();
    final updated = await _service.updateClient(client.id, payload);
    return updated;
  }

  @override
  Future<Client> adjustBalance(String clientId, double delta, String lastMovement) async {
    final client = await getClientById(clientId);
    if (client == null) throw StateError('Cliente no encontrado: $clientId');
    final updated = client.copyWith(
      balance: (client.balance + delta).toDouble(),
      lastMovement: lastMovement,
    );
    return updateClient(updated);
  }
}
