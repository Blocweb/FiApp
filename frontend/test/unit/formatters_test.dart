import 'package:flutter_test/flutter_test.dart';
import 'package:fiapp/core/utils/formatters.dart';

void main() {
  group('Formatters.currency', () {
    test('formatea enteros con símbolo de peso', () {
      expect(Formatters.currency(47500), contains('47'));
      expect(Formatters.currency(47500), startsWith(r'$'));
    });

    test('formatea cero', () {
      expect(Formatters.currency(0), startsWith(r'$'));
    });
  });

  group('Formatters.initials', () {
    test('toma hasta dos iniciales', () {
      expect(Formatters.initials('Ana Pérez'), 'AP');
    });

    test('un solo nombre', () {
      expect(Formatters.initials('Carlos'), 'C');
    });

    test('ignora espacios extra', () {
      expect(Formatters.initials('  María  López  '), 'ML');
    });
  });

  group('Formatters.uid', () {
    test('genera identificador de 7 caracteres', () {
      final id = Formatters.uid();
      expect(id.length, 7);
      expect(id, matches(RegExp(r'^[a-z0-9]+$')));
    });
  });
}
