import 'package:flutter/material.dart';
import 'package:fiapp/core/theme/app_colors.dart';

class _NavTab {
  final String route;
  final String label;
  final IconData icon;

  const _NavTab({required this.route, required this.label, required this.icon});
}

/// Barra de navegación inferior con 4 pestañas: Inicio, Clientes, Historial
/// y Ajustes. Equivalente a `BottomNav` del prototipo original, incluyendo
/// el pequeño punto indicador bajo el ícono activo.
class AppBottomNav extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String> onNavigate;

  const AppBottomNav({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
  });

  static const _tabs = [
    _NavTab(route: '/home', label: 'Inicio', icon: Icons.home_outlined),
    _NavTab(route: '/clients', label: 'Clientes', icon: Icons.people_outline),
    _NavTab(route: '/history', label: 'Historial', icon: Icons.history),
    _NavTab(route: '/settings', label: 'Ajustes', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: _tabs.map((tab) {
            final isActive = activeRoute == tab.route;
            return Expanded(
              child: InkWell(
                onTap: () => onNavigate(tab.route),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            tab.icon,
                            size: 22,
                            color: isActive ? AppColors.blue : AppColors.muted,
                          ),
                          if (isActive)
                            Positioned(
                              bottom: -6,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? AppColors.blue : AppColors.muted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
