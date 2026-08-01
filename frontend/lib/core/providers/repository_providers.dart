import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/features/clients/data/repositories/client_repository_mock_impl.dart';
import 'package:fiapp/features/clients/data/repositories/client_repository_remote_impl.dart';
import 'package:fiapp/features/clients/domain/repositories/client_repository.dart';
import 'package:fiapp/features/history/data/repositories/transaction_repository_mock_impl.dart';
import 'package:fiapp/features/history/domain/repositories/transaction_repository.dart';

/// Provider del repositorio de clientes.
///
/// Hoy expone la implementación mock. Cuando exista la API REST en
/// ASP.NET Core, basta con cambiar esta línea por
/// `ClientRepositoryRemoteImpl(ApiClient.instance.dio)` — ningún otro
/// archivo de la capa de presentación necesita modificarse.
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryRemoteImpl();
});

/// Provider del repositorio de transacciones (fiados y abonos).
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryMockImpl();
});
