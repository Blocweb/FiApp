import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa un cliente de la tienda.
///
/// Es un objeto plano de negocio, independiente de cómo se obtenga
/// (mock local hoy, API REST en ASP.NET Core más adelante).
class Client extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;

  /// Color identificador del avatar del cliente (ARGB int de Flutter).
  final int color;

  /// Saldo pendiente que el cliente debe a la tienda.
  final double balance;

  /// Fecha del último movimiento.
  final DateTime? lastMovement;

  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.color,
    required this.balance,
    required this.lastMovement,
  });

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    int? color,
    double? balance,
    DateTime? lastMovement,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      lastMovement: lastMovement ?? this.lastMovement,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        notes,
        color,
        balance,
        lastMovement,
      ];
}
