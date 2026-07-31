import 'package:flutter/material.dart';
import 'package:fiapp/core/widgets/app_bottom_nav.dart';

/// Contenedor con la barra de navegación inferior persistente para las
/// rutas raíz (Inicio, Clientes, Historial, Ajustes), equivalente al
/// `Stack` con `BottomNav` fijo del componente `App` original.
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final ValueChanged<String> onNavigate;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: AppBottomNav(
        activeRoute: currentRoute,
        onNavigate: onNavigate,
      ),
    );
  }
}
