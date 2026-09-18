import 'package:dio/dio.dart';
import 'package:fiapp/core/network/api_client.dart';
import 'package:fiapp/features/reportes/data/models/reporte_model.dart';

class ReporteApiService {
  final Dio _dio;

  ReporteApiService([Dio? dio]) : _dio = dio ?? ApiClient.instance.dio;

  Future<ResumenNegocioModel> getResumen() async {
    final resp = await _dio.get('/reportes/resumen');
    final data = resp.data;
    // El endpoint retorna una lista de 1 row con los datos del owner
    if (data is List && data.isNotEmpty) {
      return ResumenNegocioModel.fromJson(data.first as Map<String, dynamic>);
    }
    return const ResumenNegocioModel(
      totalPorCobrar: 0,
      totalClientes: 0,
      clientesConDeuda: 0,
      cobrosHoy: 0,
    );
  }

  Future<List<EvolucionMensualModel>> getEvolucion() async {
    final resp = await _dio.get('/reportes/evolucion');
    final data = resp.data as List<dynamic>;
    return data.map((e) => EvolucionMensualModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
