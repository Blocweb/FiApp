import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/widgets/app_shell.dart';
import 'package:fiapp/features/abonos/presentation/screens/register_abono_screen.dart';
import 'package:fiapp/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:fiapp/features/auth/presentation/screens/login_screen.dart';
import 'package:fiapp/features/auth/presentation/screens/new_password_screen.dart';
import 'package:fiapp/features/auth/presentation/screens/register_screen.dart';
import 'package:fiapp/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/presentation/screens/client_detail_screen.dart';
import 'package:fiapp/features/clients/presentation/screens/clients_screen.dart';
import 'package:fiapp/features/clients/presentation/screens/new_client_screen.dart';
import 'package:fiapp/features/fiados/presentation/screens/register_fiado_screen.dart';
import 'package:fiapp/features/history/presentation/screens/history_screen.dart';
import 'package:fiapp/features/home/presentation/screens/home_screen.dart';
import 'package:fiapp/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:fiapp/features/settings/presentation/screens/change_password_screen.dart';
import 'package:fiapp/features/settings/presentation/screens/export_info_screen.dart';
import 'package:fiapp/features/settings/presentation/screens/profile_screen.dart';
import 'package:fiapp/features/settings/presentation/screens/reportes_screen.dart';
import 'package:fiapp/features/settings/presentation/screens/settings_screen.dart';
import 'package:fiapp/features/splash/presentation/screens/splash_screen.dart';

/// Nombres de ruta usados en toda la app, para evitar strings sueltos.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyCode = '/verify-code';
  static const newPassword = '/new-password';
  static const home = '/home';
  static const clients = '/clients';
  static const history = '/history';
  static const settings = '/settings';
  static const newClient = '/new-client';
  static const clientDetail = '/client-detail';
  static const registerFiado = '/register-fiado';
  static const registerAbono = '/register-abono';
  static const profile = '/settings/profile';
  static const changePassword = '/settings/change-password';
  static const reportes = '/settings/reportes';
  static const exportInfo = '/settings/export-info';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// Configuración central de navegación de FiApp usando GoRouter.
///
/// Las 4 pantallas principales (Inicio, Clientes, Historial, Ajustes) se
/// muestran dentro de un [ShellRoute] que mantiene la barra de navegación
/// inferior persistente, igual que el comportamiento del prototipo React
/// original (donde `BottomNav` se pintaba fuera del contenido de pantalla).
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => AppRoutes.splash,
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.verifyCode,
      builder: (context, state) {
        final email = state.extra as String?;
        return VerifyCodeScreen(email: email);
      },
    ),
    GoRoute(
      path: AppRoutes.newPassword,
      builder: (context, state) => const NewPasswordScreen(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(
          currentRoute: state.matchedLocation,
          onNavigate: (route) => context.go(route),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.clients,
          builder: (context, state) => const ClientsScreen(),
        ),
        GoRoute(
          path: AppRoutes.history,
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: 'change-password',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
            GoRoute(
              path: 'reportes',
              builder: (context, state) => const ReportesScreen(),
            ),
            GoRoute(
              path: 'export-info',
              builder: (context, state) => const ExportInfoScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.newClient,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NewClientScreen(),
    ),
    GoRoute(
      path: AppRoutes.clientDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final client = state.extra as Client;
        return ClientDetailScreen(client: client);
      },
    ),
    GoRoute(
      path: AppRoutes.registerFiado,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final client = state.extra as Client?;
        return RegisterFiadoScreen(client: client);
      },
    ),
    GoRoute(
      path: AppRoutes.registerAbono,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final client = state.extra as Client?;
        return RegisterAbonoScreen(client: client);
      },
    ),
  ],
);
