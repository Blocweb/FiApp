import 'package:flutter_test/flutter_test.dart';
import 'package:fiapp/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('valores por defecto de desarrollo', () {
      expect(AppConfig.environment, 'development');
      expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:8000');
      expect(AppConfig.isDevelopment, isTrue);
    });
  });
}
