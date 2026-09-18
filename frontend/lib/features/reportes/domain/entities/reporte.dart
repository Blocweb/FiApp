/// Entidad de dominio que representa el resumen del negocio.
class ResumenNegocio {
  final double totalPorCobrar;
  final int totalClientes;
  final int clientesConDeuda;
  final double cobrosHoy;

  const ResumenNegocio({
    required this.totalPorCobrar,
    required this.totalClientes,
    required this.clientesConDeuda,
    required this.cobrosHoy,
  });
}

/// Entidad de dominio que representa la evolución mensual.
class EvolucionMensual {
  final DateTime mes;
  final double totalFiado;
  final double totalAbono;
  final int cantidadFiados;
  final int cantidadAbonos;

  const EvolucionMensual({
    required this.mes,
    required this.totalFiado,
    required this.totalAbono,
    required this.cantidadFiados,
    required this.cantidadAbonos,
  });
}
