import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fiapp/core/debug/session_debug_log.dart';
import 'package:fiapp/core/router/app_router.dart';
import 'package:fiapp/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  logSupabaseSessionSnapshot('Supabase.initialize persisted session');

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
