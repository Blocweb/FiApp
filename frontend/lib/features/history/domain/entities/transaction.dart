import 'package:equatable/equatable.dart';
import 'package:fiapp/features/fiados/domain/entities/fiado_item.dart';

/// Tipo de movimiento registrado para un cliente.
enum TransactionType { fiado, abono }

/// Un movimiento (fiado o abono) asociado a un cliente.
class Transaction extends Equatable {
  final String id;
  final String clientId;
  final TransactionType type;

  /// Texto descriptivo de fecha relativa (ej: "Hoy", "Ayer", "Hace 2 días").
  final String date;

  /// Hora en formato `HH:mm`.
  final String time;

  final double amount;

  /// Productos del fiado. Solo aplica cuando [type] es [TransactionType.fiado].
  final List<FiadoItem>? items;

  /// Método de pago. Solo aplica cuando [type] es [TransactionType.abono].
  final String? paymentMethod;

  final String? note;

  /// Saldo del cliente inmediatamente después de este movimiento.
  final double balanceAfter;

  /// Nombre (o correo) de quien registró el movimiento (HU03 · T17).
  final String? registeredByName;

  const Transaction({
    required this.id,
    required this.clientId,
    required this.type,
    required this.date,
    required this.time,
    required this.amount,
    this.items,
    this.paymentMethod,
    this.note,
    required this.balanceAfter,
    this.registeredByName,
  });

  bool get isFiado => type == TransactionType.fiado;

  @override
  List<Object?> get props => [
        id,
        clientId,
        type,
        date,
        time,
        amount,
        items,
        paymentMethod,
        note,
        balanceAfter,
        registeredByName,
      ];
}
