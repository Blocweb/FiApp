import 'package:fiapp/core/mock/mock_data.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/features/clients/data/models/client_model.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/domain/repositories/client_repository.dart';

/// Implementación en memoria de [ClientRepository].
///
/// Simula el comportamiento de la futura API REST en ASP.NET Core
/// (incluyendo una pequeña latencia de red) mientras el backend no existe.
/// Cuando el backend esté listo, se debe crear una
/// `ClientRepositoryRemoteImpl` que use [ApiClient] y reemplazarla en el
/// provider correspondiente — la interfaz [ClientRepository] no cambia.
class ClientRepositoryMockImpl implements ClientRepository {
  final List<ClientModel> _clients = List.of(MockData.clients);

  static const _simulatedLatency = Duration(milliseconds: 250);

  @override
  Future<List<Client>> getClients() async {
    await Future.delayed(_simulatedLatency);
    return List.unmodifiable(_clients);
  }

  @override
  Future<Client?> getClientById(String id) async {
    await Future.delayed(_simulatedLatency);
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Client> createClient(Client client) async {
    await Future.delayed(_simulatedLatency);
    final withId = ClientModel.fromEntity(
      client.copyWith(id: client.id.isEmpty ? Formatters.uid() : client.id),
    );
    _clients.insert(0, withId);
    return withId;
  }

  @override
  Future<Client> updateClient(Client client) async {
    await Future.delayed(_simulatedLatency);
    final index = _clients.indexWhere((c) => c.id == client.id);
    final updated = ClientModel.fromEntity(client);
    if (index != -1) {
      _clients[index] = updated;
    }
    return updated;
  }

  @override
  Future<Client> adjustBalance(
    String clientId,
    double delta,
    String lastMovement,
  ) async {
    await Future.delayed(_simulatedLatency);
    final index = _clients.indexWhere((c) => c.id == clientId);
    if (index == -1) {
      throw StateError('Cliente no encontrado: $clientId');
    }
    final current = _clients[index];
    final newBalance = (current.balance + delta).clamp(0, double.infinity);
    final updated = ClientModel.fromEntity(
      current.copyWith(
        balance: newBalance.toDouble(),
        lastMovement: lastMovement,
      ),
    );
    _clients[index] = updated;
    return updated;
  }
}
