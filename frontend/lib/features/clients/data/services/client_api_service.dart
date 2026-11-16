import 'package:dio/dio.dart';
import 'package:fiapp/core/network/api_client.dart';
import 'package:fiapp/features/clients/data/models/client_model.dart';

class ClientApiService {
  final Dio _dio;

  ClientApiService([Dio? dio]) : _dio = dio ?? ApiClient.instance.dio;

  Future<List<ClientModel>> getClients({String? query}) async {
    final q = query?.trim();
    final resp = await _dio.get(
      '/clientes/',
      queryParameters: q == null || q.isEmpty ? null : {'q': q},
    );
    final data = resp.data as List<dynamic>;
    return data.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClientModel> createClient(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/clientes/', data: payload);
    return ClientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ClientModel> getClientById(String id) async {
    final resp = await _dio.get('/clientes/$id');
    return ClientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ClientModel> updateClient(String id, Map<String, dynamic> payload) async {
    final resp = await _dio.put('/clientes/$id', data: payload);
    return ClientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteClient(String id) async {
    await _dio.delete('/clientes/$id');
  }
}
