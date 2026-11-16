import 'package:equatable/equatable.dart';

/// Roles del negocio tal como los maneja la API (`tenant_usuarios.rol`).
///
/// En el backlog, "administrador" corresponde a propietario/administrador y
/// "trabajador" a cobrador.
class UserRoles {
  UserRoles._();

  static const owner = 'propietario';
  static const admin = 'administrador';
  static const supervisor = 'supervisor';
  static const worker = 'cobrador';

  static bool isAdmin(String? role) => role == owner || role == admin;

  static bool seesWholeBusiness(String? role) => isAdmin(role) || role == supervisor;

  static String label(String role) {
    switch (role) {
      case owner:
        return 'Propietario';
      case admin:
        return 'Administrador';
      case supervisor:
        return 'Supervisor';
      case worker:
        return 'Trabajador';
      default:
        return role;
    }
  }
}

/// Usuario (membresía) del negocio (HU01).
class AppUser extends Equatable {
  /// Id de la membresía en `tenant_usuarios`.
  final String id;
  final String profileId;
  final String? name;
  final String email;
  final String role;
  final bool active;

  /// `true` si es el usuario que tiene la sesión abierta.
  final bool isMe;

  const AppUser({
    required this.id,
    required this.profileId,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.isMe = false,
  });

  String get displayName => (name == null || name!.trim().isEmpty) ? email : name!;

  bool get isOwner => role == UserRoles.owner;

  AppUser copyWith({String? role, bool? active}) {
    return AppUser(
      id: id,
      profileId: profileId,
      name: name,
      email: email,
      role: role ?? this.role,
      active: active ?? this.active,
      isMe: isMe,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['nombre'] as String?,
      email: json['email'] as String? ?? '',
      role: json['rol'] as String,
      active: json['activo'] as bool? ?? true,
      isMe: json['es_usted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, profileId, name, email, role, active, isMe];
}

/// Negocio seleccionado y rol del usuario en él (`GET /tenants/current`).
class CurrentMembership extends Equatable {
  final String tenantId;
  final String businessName;
  final String role;
  final String email;

  const CurrentMembership({
    required this.tenantId,
    required this.businessName,
    required this.role,
    required this.email,
  });

  bool get isAdmin => UserRoles.isAdmin(role);

  bool get isOwner => role == UserRoles.owner;

  bool get seesWholeBusiness => UserRoles.seesWholeBusiness(role);

  factory CurrentMembership.fromJson(Map<String, dynamic> json) {
    return CurrentMembership(
      tenantId: json['tenant_id'] as String,
      businessName: json['nombre_comercial'] as String? ?? '',
      role: json['rol'] as String,
      email: json['email'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [tenantId, businessName, role, email];
}
