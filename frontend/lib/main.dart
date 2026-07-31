import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiapp/core/router/app_router.dart';
import 'package:fiapp/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: FiApp()));
}

/// Widget raíz de FiApp.
///
/// Usa Material 3 ([AppTheme.light]) y GoRouter ([appRouter]) para toda la
/// navegación. El estado global (clientes, transacciones) se gestiona con
/// Riverpod a través de [ProviderScope].
class FiApp extends StatelessWidget {
  const FiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FiApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
