import 'package:fiapp/features/clients/domain/entities/client.dart';

/// Contrato del repositorio de clientes.
///
/// La capa de presentación (providers) depende únicamente de esta interfaz,
/// nunca de la implementación concreta. Esto permite sustituir la fuente de
/// datos (mock local -> API REST en ASP.NET Core) sin tocar la UI.
abstract class ClientRepository {
  /// Obtiene todos los clientes de la tienda.
  Future<List<Client>> getClients();

  /// Obtiene un cliente por su id, o `null` si no existe.
  Future<Client?> getClientById(String id);

  /// Crea un nuevo cliente y lo devuelve ya persistido (con id asignado).
  Future<Client> createClient(Client client);

  /// Actualiza los datos de un cliente existente.
  Future<Client> updateClient(Client client);

  /// Ajusta el saldo de un cliente sumando [delta] (positivo para fiado,
  /// negativo para abono) y actualiza su `lastMovement`.
  Future<Client> adjustBalance(String clientId, double delta, String lastMovement);
}
