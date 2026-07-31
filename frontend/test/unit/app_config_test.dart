import 'package:flutter_test/flutter_test.dart';
import 'package:fiapp/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('valores por defecto de desarrollo', () {
      expect(AppConfig.environment, 'development');
      expect(AppConfig.apiBaseUrl, 'https://localhost:5001/api');
      expect(AppConfig.useMockRepositories, isTrue);
      expect(AppConfig.isDevelopment, isTrue);
    });
  });
}
