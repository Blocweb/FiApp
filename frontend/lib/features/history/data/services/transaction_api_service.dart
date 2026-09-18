import 'package:dio/dio.dart';
import 'package:fiapp/core/network/api_client.dart';
import 'package:fiapp/features/history/data/models/transaction_model.dart';

class TransactionApiService {
  final Dio _dio;

  TransactionApiService([Dio? dio]) : _dio = dio ?? ApiClient.instance.dio;

  Future<List<TransactionModel>> getTransactions() async {
    final response = await _dio.get('/transacciones/');
    return _parseList(response.data);
  }

  Future<List<TransactionModel>> getTransactionsByClient(String clientId) async {
    final response = await _dio.get('/transacciones/cliente/$clientId');
    return _parseList(response.data);
  }

  Future<TransactionModel> registerFiado(Map<String, dynamic> payload) async {
    final response = await _dio.post('/transacciones/fiado', data: payload);
    return TransactionModel.fromApiJson(response.data as Map<String, dynamic>);
  }

  Future<TransactionModel> registerAbono(Map<String, dynamic> payload) async {
    final response = await _dio.post('/transacciones/abono', data: payload);
    return TransactionModel.fromApiJson(response.data as Map<String, dynamic>);
  }

  List<TransactionModel> _parseList(dynamic data) {
    final list = data as List<dynamic>;
    return list
        .map((item) => TransactionModel.fromApiJson(item as Map<String, dynamic>))
        .toList();
  }
}