import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/core/providers/repository_providers.dart';
import 'package:fiapp/features/fiados/domain/entities/fiado_item.dart';
import 'package:fiapp/features/history/domain/entities/transaction.dart';

class TransactionsState {
  final List<Transaction> transactions;
  final bool isLoading;

  const TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controlador del estado global de movimientos.
///
/// Equivale al `useState<Transaction[]>(INIT_TX)` del componente `App`
/// original.
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final Ref ref;

  TransactionsNotifier(this.ref) : super(const TransactionsState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(transactionRepositoryProvider);
    final txs = await repo.getTransactions();
    state = state.copyWith(transactions: txs, isLoading: false);
  }

  List<Transaction> byClient(String clientId) {
    return state.transactions.where((t) => t.clientId == clientId).toList();
  }

  Future<Transaction> registerFiado({
    required String clientId,
    required List<FiadoItem> items,
    required double newBalanceAfter,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    final tx = await repo.registerFiado(
      clientId: clientId,
      items: items,
      newBalanceAfter: newBalanceAfter,
    );
    state = state.copyWith(transactions: [tx, ...state.transactions]);
    return tx;
  }

  Future<Transaction> registerAbono({
    required String clientId,
    required double amount,
    required String paymentMethod,
    String? note,
    required double newBalanceAfter,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    final tx = await repo.registerAbono(
      clientId: clientId,
      amount: amount,
      paymentMethod: paymentMethod,
      note: note,
      newBalanceAfter: newBalanceAfter,
    );
    state = state.copyWith(transactions: [tx, ...state.transactions]);
    return tx;
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(ref);
});
