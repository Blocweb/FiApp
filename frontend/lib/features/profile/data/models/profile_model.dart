import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.nombreNegocio,
    required super.email,
    required super.plan,
    required super.rol,
    required super.modoOscuro,
    required super.respaldoNube,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      nombreNegocio: json['nombre_negocio'] as String,
      email: json['email'] as String,
      plan: json['plan'] as String,
      rol: json['rol'] as String,
      modoOscuro: json['modo_oscuro'] as bool,
      respaldoNube: json['respaldo_nube'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
