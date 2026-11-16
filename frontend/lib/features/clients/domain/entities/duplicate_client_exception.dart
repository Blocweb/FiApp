/// El cliente ya existe en el negocio con la misma identificación (HU02 · T10).
class DuplicateClientException implements Exception {
  final String message;
  final String? existingClientId;
  final String? existingClientName;

  const DuplicateClientException({
    required this.message,
    this.existingClientId,
    this.existingClientName,
  });

  @override
  String toString() => message;
}
