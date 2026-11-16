import 'package:fiapp/features/clients/domain/entities/client.dart';

/// Contrato del repositorio de clientes.
///
/// La capa de presentación (providers) depende únicamente de esta interfaz,
/// nunca de la implementación concreta. Esto permite sustituir la fuente de
/// datos (mock local -> API REST en ASP.NET Core) sin tocar la UI.
abstract class ClientRepository {
  /// Obtiene los clientes del negocio; [query] filtra por nombre o
  /// identificación (HU02 · T13).
  Future<List<Client>> getClients({String? query});

  /// Obtiene un cliente por su id, o `null` si no existe.
  Future<Client?> getClientById(String id);

  /// Crea un nuevo cliente y lo devuelve ya persistido (con id asignado).
  Future<Client> createClient(Client client);

  /// Actualiza los datos de un cliente existente.
  Future<Client> updateClient(Client client);

  /// Elimina un cliente lógicamente.
  Future<void> deleteClient(String id);
}
