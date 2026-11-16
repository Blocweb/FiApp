import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiapp/core/providers/repository_providers.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/domain/entities/duplicate_client_exception.dart';
import 'package:fiapp/features/clients/domain/repositories/client_repository.dart';
import 'package:fiapp/features/clients/presentation/screens/new_client_screen.dart';

/// Repositorio falso: cualquier creación responde "cliente duplicado".
class _DuplicateRepository implements ClientRepository {
  Client? received;

  @override
  Future<Client> createClient(Client client) async {
    received = client;
    throw const DuplicateClientException(
      message: 'Ya existe un cliente con la identificación 1036555444: Carlos Ruiz',
      existingClientId: 'c1',
      existingClientName: 'Carlos Ruiz',
    );
  }

  @override
  Future<List<Client>> getClients({String? query}) async => [];

  @override
  Future<Client?> getClientById(String id) async => null;

  @override
  Future<Client> updateClient(Client client) async => client;

  @override
  Future<void> deleteClient(String id) async {}
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
    matching: find.byType(TextField),
  );
  await tester.enterText(field.first, text);
  await tester.pump();
}

void main() {
  testWidgets('HU02: exige autorización y avisa cuando el cliente ya existe', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final repository = _DuplicateRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clientRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: NewClientScreen())),
      ),
    );

    await _type(tester, 'Nombre *', 'Carlos Ruiz');
    await _type(tester, 'Identificación (cédula o NIT) *', '1.036.555.444');
    await _type(tester, 'Teléfono *', '300 555 4444');

    // Sin autorización (Ley 1581 de 2012) no se puede guardar.
    await tester.tap(find.text('Guardar cliente'));
    await tester.pump();
    expect(repository.received, isNull);

    await tester.tap(find.byKey(const Key('consent-checkbox')));
    await tester.pump();
    await tester.tap(find.text('Guardar cliente'));
    await tester.pumpAndSettle();

    expect(repository.received?.identification, '1036555444');
    expect(repository.received?.dataConsent, isTrue);
    expect(find.text('El cliente ya existe'), findsOneWidget);
    expect(find.text('Ver cliente'), findsOneWidget);
  });
}
