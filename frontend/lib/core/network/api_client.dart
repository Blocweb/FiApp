import 'package:dio/dio.dart';
import 'package:fiapp/core/config/app_config.dart';

/// Cliente HTTP centralizado para consumir la API REST (ASP.NET Core).
///
/// Hoy los repositorios usan datasources mock. Cuando el backend esté
/// disponible:
///   1. Ajusta [AppConfig.apiBaseUrl] (o `--dart-define=API_BASE_URL=...`).
///   2. Sustituye los repositorios mock por implementaciones remotas que
///      usen esta instancia de [Dio].
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Interceptor para adjuntar el token JWT cuando exista autenticación.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // final token = await SecureStorage.readToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  static ApiClient get instance => _instance;

  late final Dio _dio;

  Dio get dio => _dio;
}
