import 'package:fiapp/features/history/domain/entities/transaction.dart';
import 'package:fiapp/features/fiados/domain/entities/fiado_item.dart';

/// Contrato del repositorio de movimientos (fiados y abonos).
abstract class TransactionRepository {
  /// Devuelve todos los movimientos, ordenados del más reciente al más
  /// antiguo (igual que `INIT_TX` en el prototipo original).
  Future<List<Transaction>> getTransactions();

  /// Devuelve los movimientos de un cliente específico.
  Future<List<Transaction>> getTransactionsByClient(String clientId);

  /// Registra un nuevo fiado para [clientId] con la lista de [items].
  /// Devuelve la transacción creada.
  Future<Transaction> registerFiado({
    required String clientId,
    required List<FiadoItem> items,
    required double newBalanceAfter,
    DateTime? date,
  });

  /// Registra un nuevo abono para [clientId].
  /// Devuelve la transacción creada.
  Future<Transaction> registerAbono({
    required String clientId,
    required double amount,
    required String paymentMethod,
    String? note,
    required double newBalanceAfter,
  });
}
