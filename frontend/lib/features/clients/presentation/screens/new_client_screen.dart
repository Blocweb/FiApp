import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/network/api_error.dart';
import 'package:fiapp/core/theme/app_animations.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';
import 'package:fiapp/core/widgets/app_top_bar.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/domain/entities/duplicate_client_exception.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';

/// Pantalla para registrar un nuevo cliente (HU02 · T11, T12).
///
/// Pide el nombre real, la identificación, un teléfono de contacto y la
/// autorización del cliente para el tratamiento de sus datos (Ley 1581 de
/// 2012). Si la identificación ya existe, avisa y ofrece abrir ese cliente.
class NewClientScreen extends ConsumerStatefulWidget {
  const NewClientScreen({super.key});

  @override
  ConsumerState<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends ConsumerState<NewClientScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Color _color = AppColors.clientPalette.first;
  bool _saved = false;
  bool _saving = false;
  bool _consent = false;
  String _savedName = '';
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  static String normalizeId(String value) =>
      value.replaceAll(RegExp(r'[\s.]'), '').toUpperCase();

  /// Valida el formulario; devuelve el mensaje del primer error o `null`.
  String? _validate() {
    final name = _nameController.text.trim();
    final id = normalizeId(_idController.text);
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty) return 'Escribe el nombre real del cliente';
    if (!RegExp(r'^[0-9A-Z-]{5,20}$').hasMatch(id)) {
      return 'La identificación debe tener entre 5 y 20 dígitos';
    }
    if (phoneDigits.length < 7) return 'Escribe un teléfono de contacto válido';
    if (!_consent) return 'El cliente debe autorizar el tratamiento de sus datos';
    return null;
  }

  bool get _canSave =>
      !_saving &&
      _nameController.text.trim().isNotEmpty &&
      _idController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _consent;

  Future<void> _handleSave() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    final name = _nameController.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });

    final newClient = Client(
      id: '',
      name: name,
      identification: normalizeId(_idController.text),
      phone: _phoneController.text.trim(),
      address: _addressController.text,
      notes: _notesController.text,
      // ignore: deprecated_member_use
      color: _color.value,
      balance: 0,
      lastMovement: DateTime.now(),
      dataConsent: _consent,
    );

    try {
      await ref.read(clientsProvider.notifier).addClient(newClient);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _savedName = name;
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      context.pop();
    } on DuplicateClientException catch (duplicate) {
      if (!mounted) return;
      setState(() => _saving = false);
      await _showDuplicateDialog(duplicate);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = apiErrorMessage(e, fallback: 'No se pudo crear el cliente');
      });
    }
  }

  /// HU02 · T10: aviso cuando el cliente ya existe.
  Future<void> _showDuplicateDialog(DuplicateClientException duplicate) async {
    final notifier = ref.read(clientsProvider.notifier);
    final openExisting = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('El cliente ya existe'),
        content: Text(duplicate.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cerrar'),
          ),
          if (duplicate.existingClientId != null)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ver cliente'),
            ),
        ],
      ),
    );
    if (openExisting != true || !mounted) return;
    final existing = notifier.findById(duplicate.existingClientId!) ??
        await notifier.refreshClient(duplicate.existingClientId!);
    if (existing == null || !mounted) return;
    context.pop();
    context.push('/client-detail', extra: existing);
  }

  @override
  Widget build(BuildContext context) {
    if (_saved) {
      return _SuccessView(name: _savedName);
    }

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          AppTopBar(title: 'Nuevo cliente', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _nameController.text.trim().isEmpty
                            ? '?'
                            : Formatters.initials(_nameController.text),
                        style: TextStyle(color: _color, fontSize: 26, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: AppColors.clientPalette.map((c) {
                        // ignore: deprecated_member_use
                        final selected = c.value == _color.value;
                        return GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? AppColors.ink : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      AppInput(
                        label: 'Nombre *',
                        value: _nameController.text,
                        onChanged: (v) => setState(() => _nameController.text = v),
                        placeholder: 'Ej: María García',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Identificación (cédula o NIT) *',
                        value: _idController.text,
                        onChanged: (v) => setState(() => _idController.text = v),
                        keyboardType: TextInputType.number,
                        placeholder: 'Ej: 1036123456',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Teléfono *',
                        value: _phoneController.text,
                        onChanged: (v) => setState(() => _phoneController.text = v),
                        keyboardType: TextInputType.phone,
                        placeholder: 'Ej: 311 456 7890',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Dirección',
                        value: _addressController.text,
                        onChanged: (v) => _addressController.text = v,
                        placeholder: 'Ej: Cra 5 #23-41',
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Notas',
                        value: _notesController.text,
                        onChanged: (v) => _notesController.text = v,
                        multiline: true,
                        placeholder: 'Observaciones del cliente...',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  onTap: () => setState(() => _consent = !_consent),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        key: const Key('consent-checkbox'),
                        value: _consent,
                        onChanged: (v) => setState(() => _consent = v ?? false),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'El cliente autoriza al Almacén y Taller El Hermano a tratar sus datos '
                          'personales para registrar y cobrar sus compras a crédito, conforme a la '
                          'Ley 1581 de 2012.',
                          style: TextStyle(fontSize: 13, color: AppColors.ink, fontFamily: 'Inter', height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red, fontSize: 13, fontFamily: 'Inter'),
                    ),
                  ),
                const SizedBox(height: 16),
                AppButton(
                  label: _saving ? 'Guardando...' : 'Guardar cliente',
                  fullWidth: true,
                  disabled: !_canSave,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String name;

  const _SuccessView({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppAnimations.successPop,
              curve: AppAnimations.successPopCurve,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0, 1),
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_circle_outline, size: 40, color: AppColors.green),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Cliente agregado!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            Text(
              '$name fue creado exitosamente',
              style: const TextStyle(fontSize: 14, color: AppColors.muted, fontFamily: 'Inter'),
            ),
          ],
        ),
      ),
    );
  }
}
