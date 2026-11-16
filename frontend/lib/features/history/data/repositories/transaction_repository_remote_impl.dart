import 'package:fiapp/features/fiados/domain/entities/fiado_item.dart';
import 'package:fiapp/features/history/data/services/transaction_api_service.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';
import 'package:fiapp/features/history/domain/repositories/transaction_repository.dart';

class TransactionRepositoryRemoteImpl implements TransactionRepository {
  final TransactionApiService _service;

  TransactionRepositoryRemoteImpl([TransactionApiService? service])
      : _service = service ?? TransactionApiService();

  @override
  Future<List<Transaction>> getTransactions() {
    return _service.getTransactions();
  }

  @override
  Future<List<Transaction>> getTransactionsByClient(String clientId) {
    return _service.getTransactionsByClient(clientId);
  }

  @override
  Future<Transaction> registerFiado({
    required String clientId,
    required List<FiadoItem> items,
    required double newBalanceAfter,
    DateTime? date,
  }) {
    final amount = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    return _service.registerFiado({
      'cliente_id': clientId,
      'monto': amount,
      if (date != null) 'fecha_hora': date.toUtc().toIso8601String(),
      'items': items
          .map(
            (item) => {
              // Los productos escritos manualmente no tienen un UUID del
              // catalogo; su identificador local no se persiste como FK.
              'producto_id': null,
              'nombre_producto': item.name,
              'cantidad': item.qty,
              'precio_unitario': item.price,
            },
          )
          .toList(),
    });
  }

  @override
  Future<Transaction> registerAbono({
    required String clientId,
    required double amount,
    required String paymentMethod,
    String? note,
    required double newBalanceAfter,
  }) {
    final payload = <String, dynamic>{
      'cliente_id': clientId,
      'monto': amount,
      'nota': note,
    };

    final paymentMethodId = int.tryParse(paymentMethod);
    if (paymentMethodId != null) {
      payload['metodo_pago_id'] = paymentMethodId;
    } else {
      payload['metodo_pago_nombre'] = paymentMethod;
    }

    return _service.registerAbono(payload);
  }
}