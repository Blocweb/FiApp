import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/router/app_router.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_badge.dart';
import 'package:fiapp/features/auth/providers/auth_provider.dart';

class _SettingsItem {
  final String icon;
  final String label;
  final String sub;
  final String? route;
  final bool? toggle;

  _SettingsItem({required this.icon, required this.label, required this.sub, this.route, this.toggle});
}

class _SettingsSection {
  final String title;
  final List<_SettingsItem> items;

  _SettingsSection({required this.title, required this.items});
}

/// Pantalla de ajustes: perfil, preferencias (con toggles), datos, soporte
/// y cierre de sesión. Réplica de `SettingsScreen` del prototipo original.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _cloudBackup = true;

  List<_SettingsSection> get _sections => [
        _SettingsSection(
          title: 'Mi cuenta',
          items: [
            _SettingsItem(icon: '👤', label: 'Mi perfil', sub: 'Nombre, correo', route: AppRoutes.profile),
            _SettingsItem(icon: '🔒', label: 'Cambiar contraseña', sub: '••••••••', route: AppRoutes.changePassword),
          ],
        ),
        _SettingsSection(
          title: 'Preferencias',
          items: [
            _SettingsItem(icon: '🌙', label: 'Modo oscuro', sub: 'Tema oscuro de la app', toggle: _darkMode),
            _SettingsItem(icon: '☁️', label: 'Respaldo en la nube', sub: 'Sincronización automática', toggle: _cloudBackup),
          ],
        ),
        _SettingsSection(
          title: 'Datos',
          items: [
            _SettingsItem(icon: '📤', label: 'Exportar información', sub: 'Descargar en Excel', route: AppRoutes.exportInfo),
            _SettingsItem(icon: '📊', label: 'Reportes', sub: 'Ver resúmenes y estadísticas', route: AppRoutes.reportes),
          ],
        ),
        _SettingsSection(
          title: 'Soporte',
          items: [
            _SettingsItem(icon: '❓', label: 'Ayuda y soporte', sub: 'Preguntas frecuentes'),
            _SettingsItem(icon: 'ℹ️', label: 'Acerca de FiApp', sub: 'Versión 1.0.0'),
          ],
        ),
      ];

  void _handleToggle(String label) {
    setState(() {
      if (label == 'Modo oscuro') _darkMode = !_darkMode;
      if (label == 'Respaldo en la nube') _cloudBackup = !_cloudBackup;
    });
  }

  void _handleLogout() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final authNotifier = container.read(authNotifierProvider.notifier);
    await authNotifier.logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajustes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text(
                        'MT',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, fontFamily: 'Inter'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mi Tienda',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'mitienda@correo.com',
                          style: TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 5),
                        AppBadge(text: 'Plan gratuito', color: AppColors.blue),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              children: [
                ..._sections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            section.title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              fontFamily: 'Inter',
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: List.generate(section.items.length, (i) {
                              final item = section.items[i];
                              final isLast = i == section.items.length - 1;
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: item.toggle != null
                                        ? () => _handleToggle(item.label)
                                        : item.route != null
                                            ? () => context.go(item.route!)
                                            : () {},
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Text(item.icon, style: const TextStyle(fontSize: 20)),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.label,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, fontFamily: 'Inter'),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.sub,
                                                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (item.toggle != null)
                                            _Toggle(value: item.toggle!, onTap: () => _handleToggle(item.label))
                                          else
                                            const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.redLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.27), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.red),
                        SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(color: AppColors.red, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;

  const _Toggle({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.blue : AppColors.border,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
