import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/features/clients/data/repositories/client_repository_remote_impl.dart';
import 'package:fiapp/features/clients/domain/repositories/client_repository.dart';
import 'package:fiapp/features/history/data/repositories/transaction_repository_remote_impl.dart';
import 'package:fiapp/features/history/domain/repositories/transaction_repository.dart';

/// Provider del repositorio de clientes.
///
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryRemoteImpl();
});

/// Provider del repositorio de transacciones (fiados y abonos).
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryRemoteImpl();
});
