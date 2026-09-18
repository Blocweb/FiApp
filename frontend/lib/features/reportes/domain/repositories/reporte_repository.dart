import '../entities/reporte.dart';

abstract class ReporteRepository {
  Future<ResumenNegocio> getResumen();
  Future<List<EvolucionMensual>> getEvolucion();
}
