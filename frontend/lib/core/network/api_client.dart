import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fiapp/core/debug/session_debug_log.dart';

/// Cliente HTTP centralizado para consumir la API REST.
///
/// Configura la URL base desde `API_URL` en `.env`, un timeout de 30
/// segundos y un interceptor que agrega el token de Supabase a todas las
/// peticiones.
class ApiClient {
  ApiClient._internal() {
    final baseUrl = dotenv.env['API_URL'] ?? '';

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

          if (options.path == '/api/profile') {
            logSupabaseSessionSnapshot(
              'GET /api/profile request',
              extra: {
                'uri': options.uri,
                'authorizationAccessToken': debugAccessTokenLabel(accessToken),
              },
            );
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              'HTTP ${response.requestOptions.method} ${response.requestOptions.uri} => ${response.statusCode}',
            );
            if (response.requestOptions.path == '/api/profile') {
              debugPrint(
                '[TEMP AUTH DEBUG] GET /api/profile response '
                'status=${response.statusCode} data=${response.data}',
              );
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final request = error.requestOptions;
            debugPrint(
              'HTTP ${request.method} ${request.uri} => ${error.response?.statusCode ?? 'ERROR'}',
            );
            debugPrint('Request data: ${request.data}');
            debugPrint('Response data: ${error.response?.data}');
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
