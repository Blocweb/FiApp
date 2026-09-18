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
    try {
      return await _service.getClientById(id);
    } on Exception {
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
  Future<void> deleteClient(String id) async {
    await _service.deleteClient(id);
  }
}
