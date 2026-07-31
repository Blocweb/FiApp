import 'package:fiapp/core/mock/mock_data.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/features/fiados/domain/entities/fiado_item.dart';
import 'package:fiapp/features/history/data/models/transaction_model.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';
import 'package:fiapp/features/history/domain/repositories/transaction_repository.dart';

/// Implementación en memoria de [TransactionRepository].
///
/// Al igual que [ClientRepositoryMockImpl], simula la futura API REST en
/// ASP.NET Core. La sustitución por un datasource remoto no debería
/// requerir cambios en los providers que consumen esta interfaz.
class TransactionRepositoryMockImpl implements TransactionRepository {
  final List<TransactionModel> _transactions = List.of(MockData.transactions);

  static const _simulatedLatency = Duration(milliseconds: 250);

  @override
  Future<List<Transaction>> getTransactions() async {
    await Future.delayed(_simulatedLatency);
    return List.unmodifiable(_transactions);
  }

  @override
  Future<List<Transaction>> getTransactionsByClient(String clientId) async {
    await Future.delayed(_simulatedLatency);
    return _transactions.where((t) => t.clientId == clientId).toList();
  }

  @override
  Future<Transaction> registerFiado({
    required String clientId,
    required List<FiadoItem> items,
    required double newBalanceAfter,
  }) async {
    await Future.delayed(_simulatedLatency);
    final total = items.fold<double>(0, (sum, i) => sum + i.subtotal);
    final tx = TransactionModel(
      id: Formatters.uid(),
      clientId: clientId,
      type: TransactionType.fiado,
      date: 'Hoy',
      time: Formatters.nowTime(),
      amount: total,
      items: items,
      balanceAfter: newBalanceAfter,
    );
    _transactions.insert(0, tx);
    return tx;
  }

  @override
  Future<Transaction> registerAbono({
    required String clientId,
    required double amount,
    required String paymentMethod,
    String? note,
    required double newBalanceAfter,
  }) async {
    await Future.delayed(_simulatedLatency);
    final tx = TransactionModel(
      id: Formatters.uid(),
      clientId: clientId,
      type: TransactionType.abono,
      date: 'Hoy',
      time: Formatters.nowTime(),
      amount: amount,
      paymentMethod: paymentMethod,
      note: note,
      balanceAfter: newBalanceAfter,
    );
    _transactions.insert(0, tx);
    return tx;
  }
}
