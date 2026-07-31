import 'package:fiapp/features/clients/domain/entities/client.dart';

/// Modelo de datos de [Client].
///
/// Mapea el JSON que devolverá el futuro endpoint de ASP.NET Core
/// (`GET /api/clients`, `POST /api/clients`, etc). Mientras el backend no
/// exista, este mismo modelo se construye a partir de los datos mock,
/// manteniendo la estructura que tendrá la respuesta real de la API.
///
/// Convención de nombres esperada del backend en C# (PascalCase / camelCase
/// según serializador): se asume camelCase estándar de ASP.NET Core con
/// System.Text.Json (opciones por defecto de .NET 8), es decir:
/// ```json
/// {
///   "id": "1",
///   "name": "María García",
///   "phone": "311 456 7890",
///   "address": "Cra 5 #23-41, Barrio El Centro",
///   "notes": "Cliente frecuente",
///   "colorHex": "#8B5CF6",
///   "balance": 47500.0,
///   "lastMovement": "Hace 2 días"
/// }
/// ```
class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.address,
    required super.notes,
    required super.color,
    required super.balance,
    required super.lastMovement,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      color: _colorFromHex(json['colorHex'] as String? ?? '#2563EB'),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      lastMovement: json['lastMovement'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'colorHex': _colorToHex(color),
      'balance': balance,
      'lastMovement': lastMovement,
    };
  }

  factory ClientModel.fromEntity(Client client) {
    return ClientModel(
      id: client.id,
      name: client.name,
      phone: client.phone,
      address: client.address,
      notes: client.notes,
      color: client.color,
      balance: client.balance,
      lastMovement: client.lastMovement,
    );
  }

  static int _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return int.parse('FF$cleaned', radix: 16);
  }

  static String _colorToHex(int color) {
    return '#${color.toRadixString(16).substring(2).toUpperCase()}';
  }
}
