class Profile {
  final String id;
  final String nombreNegocio;
  final String email;
  final String plan;
  final String rol;
  final bool modoOscuro;
  final bool respaldoNube;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.nombreNegocio,
    required this.email,
    required this.plan,
    required this.rol,
    required this.modoOscuro,
    required this.respaldoNube,
    required this.createdAt,
    required this.updatedAt,
  });
}
