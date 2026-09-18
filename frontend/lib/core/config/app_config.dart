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

  /// URL base de la API FastAPI para el emulador Android.
  /// Override: `flutter run --dart-define=API_BASE_URL=https://api.ejemplo.com`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Override de máxima prioridad para builds locales o de producción.
  static const String apiUrlOverride = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static bool get isDevelopment => environment == 'development';
}
