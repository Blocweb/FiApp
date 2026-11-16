import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/network/api_error.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/widgets/app_badge.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_fab.dart';
import 'package:fiapp/core/widgets/app_top_bar.dart';
import 'package:fiapp/features/users/domain/entities/app_user.dart';
import 'package:fiapp/features/users/presentation/providers/users_provider.dart';

/// Gestión de usuarios del negocio (HU01 · T06).
///
/// El propietario o un administrador crea la cuenta propia de cada
/// trabajador y puede desactivarla o reactivarla. Los usuarios no se borran.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(currentMembershipProvider).valueOrNull;
    final isAdmin = membership?.isAdmin ?? false;

    return Container(
      color: AppColors.bg,
      child: Stack(
        children: [
          Column(
            children: [
              AppTopBar(title: 'Usuarios y roles', onBack: () => context.pop()),
              Expanded(
                child: membership != null && !isAdmin
                    ? const _Message(
                        icon: Icons.lock_outline,
                        text: 'Solo el propietario o un administrador puede gestionar usuarios.',
                      )
                    : const _UsersList(),
              ),
            ],
          ),
          if (isAdmin)
            AppFab(
              label: 'Nuevo usuario',
              onPressed: () => _openCreateSheet(context, canCreateAdmins: membership!.isOwner),
            ),
        ],
      ),
    );
  }

  void _openCreateSheet(BuildContext context, {required bool canCreateAdmins}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateUserSheet(canCreateAdmins: canCreateAdmins),
    );
  }
}

class _UsersList extends ConsumerWidget {
  const _UsersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersProvider);
    final isOwner = ref.watch(currentMembershipProvider).valueOrNull?.isOwner ?? false;

    if (state.isLoading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.users.isEmpty) {
      return _Message(icon: Icons.error_outline, text: state.error!);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(usersProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Cada trabajador entra con su propia cuenta. El trabajador solo ve los movimientos '
              'que él registra; el propietario y los administradores ven todo.',
              style: TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter', height: 1.4),
            ),
          ),
          ...state.users.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UserTile(user: user, canManageAdmins: isOwner),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final AppUser user;
  final bool canManageAdmins;

  const _UserTile({required this.user, required this.canManageAdmins});

  bool get _editable {
    if (user.isMe || user.isOwner) return false;
    if (user.role == UserRoles.admin && !canManageAdmins) return false;
    return true;
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool active) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(usersProvider.notifier).setActive(user, active);
      messenger.showSnackBar(SnackBar(
        content: Text(active ? '${user.displayName} fue reactivado' : '${user.displayName} fue desactivado'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = UserRoles.isAdmin(user.role) ? AppColors.blue : AppColors.muted;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (user.active ? AppColors.blue : AppColors.muted).withValues(alpha: 0.13),
            child: Text(
              user.displayName.isEmpty ? '?' : user.displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: user.active ? AppColors.blue : AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.isMe ? '${user.displayName} (usted)' : user.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: user.active ? AppColors.ink : AppColors.muted,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    AppBadge(text: UserRoles.label(user.role), color: roleColor),
                    if (!user.active) const AppBadge(text: 'Inactivo', color: AppColors.red),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: user.active,
            onChanged: _editable ? (value) => _toggle(context, ref, value) : null,
          ),
        ],
      ),
    );
  }
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  final bool canCreateAdmins;

  const _CreateUserSheet({required this.canCreateAdmins});

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = UserRoles.worker;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_name.text.trim().length < 2) return 'Escribe el nombre del trabajador';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      return 'Escribe un correo válido';
    }
    if (_password.text.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    return null;
  }

  Future<void> _save() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = await ref.read(usersProvider.notifier).create(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            role: _role,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cuenta creada para ${user.displayName}. Ya puede iniciar sesión con su correo.'),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = apiErrorMessage(e, fallback: 'No se pudo crear el usuario');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nuevo usuario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('user-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('user-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('user-password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña inicial',
                helperText: 'Mínimo 8 caracteres. Entrégasela al trabajador.',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                const ButtonSegment(value: UserRoles.worker, label: Text('Trabajador')),
                if (widget.canCreateAdmins)
                  const ButtonSegment(value: UserRoles.admin, label: Text('Administrador')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13, fontFamily: 'Inter')),
              ),
            const SizedBox(height: 16),
            AppButton(
              label: _saving ? 'Creando...' : 'Crear cuenta',
              fullWidth: true,
              disabled: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontFamily: 'Inter', fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
