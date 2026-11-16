import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiapp/core/network/api_error.dart';
import 'package:fiapp/features/clients/data/models/client_model.dart';
import 'package:fiapp/features/history/data/models/transaction_model.dart';
import 'package:fiapp/features/users/domain/entities/app_user.dart';

DioException _apiError(int status, Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('HU02 · ClientModel', () {
    test('lee identificación y autorización de datos de la API', () {
      final client = ClientModel.fromJson(const {
        'id': 'c1',
        'name': 'Carlos Ruiz',
        'identification': '1036555444',
        'phone': '3005554444',
        'colorHex': '#2563EB',
        'balance': 0,
        'dataConsent': true,
      });
      expect(client.identification, '1036555444');
      expect(client.dataConsent, isTrue);
    });

    test('clientes anteriores sin identificación no fallan', () {
      final client = ClientModel.fromJson(const {'id': 'c2', 'name': 'Antiguo', 'balance': 1000});
      expect(client.identification, isEmpty);
      expect(client.dataConsent, isFalse);
    });

    test('envía identificación y autorización al crear', () {
      final json = ClientModel.fromJson(const {
        'id': '',
        'name': 'Carlos Ruiz',
        'identification': '1036555444',
        'phone': '3005554444',
        'dataConsent': true,
      }).toJson();
      expect(json['identification'], '1036555444');
      expect(json['dataConsent'], isTrue);
    });
  });

  group('HU03 · TransactionModel', () {
    test('expone quién registró la venta', () {
      final tx = TransactionModel.fromApiJson(const {
        'id': 't1',
        'cliente_id': 'c1',
        'tipo': 'fiado',
        'monto': 90000,
        'saldo_posterior': 90000,
        'fecha_hora': '2026-11-10T15:30:00+00:00',
        'registrado_por_nombre': 'Pedro Gómez',
        'items': <dynamic>[],
      });
      expect(tx.registeredByName, 'Pedro Gómez');
      expect(tx.isFiado, isTrue);
    });
  });

  group('HU01 · Roles', () {
    test('propietario y administrador son administradores; cobrador no', () {
      expect(UserRoles.isAdmin('propietario'), isTrue);
      expect(UserRoles.isAdmin('administrador'), isTrue);
      expect(UserRoles.isAdmin('cobrador'), isFalse);
      expect(UserRoles.label('cobrador'), 'Trabajador');
    });

    test('AppUser usa el correo cuando no hay nombre', () {
      final user = AppUser.fromJson(const {
        'id': 'm1',
        'profile_id': 'p1',
        'nombre': null,
        'email': 'pedro@correo.co',
        'rol': 'cobrador',
        'activo': false,
      });
      expect(user.displayName, 'pedro@correo.co');
      expect(user.active, isFalse);
    });
  });

  group('apiErrorMessage', () {
    test('usa el mensaje del 409 de cliente duplicado', () {
      final error = _apiError(409, {
        'detail': {'code': 'cliente_duplicado', 'message': 'Ya existe un cliente con la identificación 123: Ana'},
      });
      expect(apiErrorMessage(error), 'Ya existe un cliente con la identificación 123: Ana');
      expect(apiErrorCode(error), 'cliente_duplicado');
    });

    test('limpia el prefijo de los errores 422', () {
      final error = _apiError(422, {
        'detail': [
          {'loc': ['body', 'dataConsent'], 'msg': 'Value error, El cliente debe autorizar'},
        ],
      });
      expect(apiErrorMessage(error), 'El cliente debe autorizar');
    });

    test('explica el 403 de usuario desactivado', () {
      expect(apiErrorMessage(_apiError(403, null)), contains('desactivado'));
    });
  });
}
