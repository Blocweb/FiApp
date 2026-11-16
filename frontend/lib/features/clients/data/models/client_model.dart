import 'package:fiapp/features/clients/domain/entities/client.dart';

/// Modelo de datos de [Client].
///
/// Mapea el JSON de la API FastAPI (`GET /clientes/`, `POST /clientes/`). Mientras el backend no
/// exista, este mismo modelo se construye a partir de los datos mock,
/// manteniendo la estructura que tendrá la respuesta real de la API.
///
/// La API usa nombres camelCase para sus contratos de cliente:
/// ```json
/// {
///   "id": "1",
///   "name": "María García",
///   "phone": "311 456 7890",
///   "address": "Cra 5 #23-41, Barrio El Centro",
///   "notes": "Cliente frecuente",
///   "colorHex": "#8B5CF6",
///   "balance": 47500.0,
///   "lastMovement": "2023-10-25T14:30:00Z"
/// }
/// ```
class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.name,
    super.identification,
    required super.phone,
    required super.address,
    required super.notes,
    required super.color,
    required super.balance,
    required super.lastMovement,
    super.dataConsent,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      identification: json['identification'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      color: _colorFromHex(json['colorHex'] as String? ?? '#2563EB'),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      lastMovement: json['lastMovement'] != null
          ? DateTime.tryParse(json['lastMovement'].toString())
          : null,
      dataConsent: json['dataConsent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (identification.isNotEmpty) 'identification': identification,
      'phone': phone,
      'address': address,
      'notes': notes,
      'colorHex': _colorToHex(color),
      if (dataConsent) 'dataConsent': true,
    };
  }

  factory ClientModel.fromEntity(Client client) {
    return ClientModel(
      id: client.id,
      name: client.name,
      identification: client.identification,
      phone: client.phone,
      address: client.address,
      notes: client.notes,
      color: client.color,
      balance: client.balance,
      lastMovement: client.lastMovement,
      dataConsent: client.dataConsent,
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
