import 'package:dio/dio.dart';
import 'package:fiapp/core/network/api_error.dart';
import 'package:fiapp/features/clients/data/models/client_model.dart';
import 'package:fiapp/features/clients/data/services/client_api_service.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/domain/entities/duplicate_client_exception.dart';
import 'package:fiapp/features/clients/domain/repositories/client_repository.dart';

class ClientRepositoryRemoteImpl implements ClientRepository {
  final ClientApiService _service;

  ClientRepositoryRemoteImpl([ClientApiService? service]) : _service = service ?? ClientApiService();

  @override
  Future<Client> createClient(Client client) async {
    final payload = ClientModel.fromEntity(client).toJson();
    try {
      return await _service.createClient(payload);
    } on DioException catch (error) {
      throw _duplicateOr(error);
    }
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
  Future<List<Client>> getClients({String? query}) async {
    final list = await _service.getClients(query: query);
    return list;
  }

  /// Traduce el 409 `cliente_duplicado` de la API a una excepción de dominio.
  Object _duplicateOr(DioException error) {
    if (error.response?.statusCode == 409 && apiErrorCode(error) == 'cliente_duplicado') {
      final detail = (error.response?.data as Map)['detail'] as Map;
      return DuplicateClientException(
        message: apiErrorMessage(error),
        existingClientId: detail['cliente_id'] as String?,
        existingClientName: detail['nombre'] as String?,
      );
    }
    return error;
  }

  @override
  Future<Client> updateClient(Client client) async {
    final payload = ClientModel.fromEntity(client).toJson();
    try {
      return await _service.updateClient(client.id, payload);
    } on DioException catch (error) {
      throw _duplicateOr(error);
    }
  }

  @override
  Future<void> deleteClient(String id) async {
    await _service.deleteClient(id);
  }
}
