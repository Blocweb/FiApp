import 'package:dio/dio.dart';

/// Convierte un error de la API FastAPI en un mensaje legible en español.
///
/// FastAPI responde `detail` como texto, como objeto `{code, message}` o,
/// en errores 422 de validación, como lista de `{loc, msg}`.
String apiErrorMessage(Object error, {String fallback = 'Ocurrió un error. Intenta de nuevo.'}) {
  if (error is! DioException) return fallback;

  final status = error.response?.statusCode;
  final data = error.response?.data;
  final detail = data is Map ? data['detail'] : null;

  if (detail is String && detail.isNotEmpty) return detail;
  if (detail is Map && detail['message'] is String) return detail['message'] as String;
  if (detail is List && detail.isNotEmpty) {
    final first = detail.first;
    if (first is Map && first['msg'] is String) {
      return (first['msg'] as String).replaceFirst('Value error, ', '');
    }
  }

  if (status == 401) return 'Tu sesión expiró. Inicia sesión de nuevo.';
  if (status == 403) return 'Tu usuario no tiene permiso para esta acción o está desactivado.';
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout) {
    return 'No hay conexión con el servidor.';
  }
  return fallback;
}

/// Código de error de negocio enviado por la API (`detail.code`), si existe.
String? apiErrorCode(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  final detail = data is Map ? data['detail'] : null;
  return detail is Map ? detail['code'] as String? : null;
}
