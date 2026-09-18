import 'package:fiapp/features/reportes/data/services/reporte_api_service.dart';
import 'package:fiapp/features/reportes/domain/entities/reporte.dart';
import 'package:fiapp/features/reportes/domain/repositories/reporte_repository.dart';

class ReporteRepositoryRemoteImpl implements ReporteRepository {
  final ReporteApiService _service;

  ReporteRepositoryRemoteImpl([ReporteApiService? service])
      : _service = service ?? ReporteApiService();

  @override
  Future<ResumenNegocio> getResumen() => _service.getResumen();

  @override
  Future<List<EvolucionMensual>> getEvolucion() => _service.getEvolucion();
}
