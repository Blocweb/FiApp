import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fiapp/core/config/app_config.dart';
import 'package:fiapp/core/debug/session_debug_log.dart';

/// Cliente HTTP centralizado para consumir la API REST.
///
/// Configura la URL base desde `API_URL` en `.env`, un timeout de 30
/// segundos y un interceptor que agrega el token de Supabase a todas las
/// peticiones.
class ApiClient {
  ApiClient._internal() {
    final compileTimeUrl = AppConfig.apiUrlOverride.trim();
    final assetUrl = dotenv.env['API_URL']?.trim();
    final baseUrl = compileTimeUrl.isNotEmpty
      ? compileTimeUrl
      : assetUrl == null || assetUrl.isEmpty
        ? AppConfig.apiBaseUrl
        : assetUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = Supabase.instance.client.auth.currentSession;
          final accessToken = session?.accessToken;

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          } else {
            options.headers.remove('Authorization');
          }

          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';

          if (options.path == '/perfil/') {
            logSupabaseSessionSnapshot('GET /perfil/ request');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              'HTTP ${response.requestOptions.method} ${response.requestOptions.uri} => ${response.statusCode}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final request = error.requestOptions;
            debugPrint(
              'HTTP ${request.method} ${request.uri} => ${error.response?.statusCode ?? 'ERROR'}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  static ApiClient get instance => _instance;

  late final Dio _dio;

  Dio get dio => _dio;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});
