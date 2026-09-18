import '../../domain/entities/reporte.dart';

class ResumenNegocioModel extends ResumenNegocio {
  const ResumenNegocioModel({
    required super.totalPorCobrar,
    required super.totalClientes,
    required super.clientesConDeuda,
    required super.cobrosHoy,
  });

  factory ResumenNegocioModel.fromJson(Map<String, dynamic> json) {
    return ResumenNegocioModel(
      totalPorCobrar: (json['total_por_cobrar'] as num?)?.toDouble() ?? 0.0,
      totalClientes: (json['total_clientes'] as num?)?.toInt() ?? 0,
      clientesConDeuda: (json['clientes_con_deuda'] as num?)?.toInt() ?? 0,
      cobrosHoy: (json['cobros_hoy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EvolucionMensualModel extends EvolucionMensual {
  const EvolucionMensualModel({
    required super.mes,
    required super.totalFiado,
    required super.totalAbono,
    required super.cantidadFiados,
    required super.cantidadAbonos,
  });

  factory EvolucionMensualModel.fromJson(Map<String, dynamic> json) {
    return EvolucionMensualModel(
      mes: DateTime.parse(json['mes'].toString()),
      totalFiado: (json['total_fiado'] as num?)?.toDouble() ?? 0.0,
      totalAbono: (json['total_abono'] as num?)?.toDouble() ?? 0.0,
      cantidadFiados: (json['cantidad_fiados'] as num?)?.toInt() ?? 0,
      cantidadAbonos: (json['cantidad_abonos'] as num?)?.toInt() ?? 0,
    );
  }
}
