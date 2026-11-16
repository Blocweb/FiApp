import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa un cliente de la tienda.
///
/// Es un objeto plano de negocio, independiente de cómo se obtenga
/// (mock local hoy, API REST en ASP.NET Core más adelante).
class Client extends Equatable {
  final String id;
  final String name;

  /// Documento del cliente (cédula/NIT), sin puntos ni espacios (HU02).
  final String identification;
  final String phone;
  final String address;
  final String notes;

  /// Color identificador del avatar del cliente (ARGB int de Flutter).
  final int color;

  /// Saldo pendiente que el cliente debe a la tienda.
  final double balance;

  /// Fecha del último movimiento.
  final DateTime? lastMovement;

  /// Autorización de tratamiento de datos (Ley 1581 de 2012).
  final bool dataConsent;

  const Client({
    required this.id,
    required this.name,
    this.identification = '',
    required this.phone,
    required this.address,
    required this.notes,
    required this.color,
    required this.balance,
    required this.lastMovement,
    this.dataConsent = false,
  });

  Client copyWith({
    String? id,
    String? name,
    String? identification,
    String? phone,
    String? address,
    String? notes,
    int? color,
    double? balance,
    DateTime? lastMovement,
    bool? dataConsent,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      identification: identification ?? this.identification,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      lastMovement: lastMovement ?? this.lastMovement,
      dataConsent: dataConsent ?? this.dataConsent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        identification,
        phone,
        address,
        notes,
        color,
        balance,
        lastMovement,
        dataConsent,
      ];
}
