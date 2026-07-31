import 'package:flutter_test/flutter_test.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';

void main() {
  group('Client', () {
    const client = Client(
      id: 'c1',
      name: 'Ana Pérez',
      phone: '3001234567',
      address: 'Calle 1',
      notes: '',
      color: 0xFF4CAF50,
      balance: 15000,
      lastMovement: 'Hoy',
    );

    test('props incluyen campos de igualdad', () {
      const other = Client(
        id: 'c1',
        name: 'Ana Pérez',
        phone: '3001234567',
        address: 'Calle 1',
        notes: '',
        color: 0xFF4CAF50,
        balance: 15000,
        lastMovement: 'Hoy',
      );
      expect(client, equals(other));
    });

    test('copyWith actualiza solo los campos indicados', () {
      final updated = client.copyWith(balance: 0, lastMovement: 'Ahora');
      expect(updated.balance, 0);
      expect(updated.lastMovement, 'Ahora');
      expect(updated.name, 'Ana Pérez');
      expect(updated.id, 'c1');
    });
  });
}
