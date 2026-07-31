/// Configuración central de la aplicación Flutter.
///
/// Los valores sensibles/desplegables deben alinearse con `config/.env.example`
/// en la raíz del monorepo. Hoy se definen como constantes; más adelante se
/// pueden inyectar vía `--dart-define` o un paquete de entorno.
class AppConfig {
  AppConfig._();

  /// Entorno de ejecución.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// URL base de la API ASP.NET Core.
  /// Override: `flutter run --dart-define=API_BASE_URL=https://api.ejemplo.com/api`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://localhost:5001/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Si es true, los providers usan repositorios mock en memoria.
  static const bool useMockRepositories = bool.fromEnvironment(
    'USE_MOCK_REPOSITORIES',
    defaultValue: true,
  );

  static bool get isDevelopment => environment == 'development';
}
