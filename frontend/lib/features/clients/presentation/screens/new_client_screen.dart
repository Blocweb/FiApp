import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_animations.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';
import 'package:fiapp/core/widgets/app_top_bar.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';

/// Pantalla para registrar un nuevo cliente. Réplica de
/// `NewClientScreen` del prototipo original: selector de color de avatar,
/// formulario y animación "successPop" al guardar.
class NewClientScreen extends ConsumerStatefulWidget {
  const NewClientScreen({super.key});

  @override
  ConsumerState<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends ConsumerState<NewClientScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Color _color = AppColors.clientPalette.first;
  bool _saved = false;
  String _savedName = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _saved = true;
      _savedName = name;
    });

    final newClient = Client(
      id: '',
      name: name,
      phone: _phoneController.text,
      address: _addressController.text,
      notes: _notesController.text,
      // ignore: deprecated_member_use
      color: _color.value,
      balance: 0,
      lastMovement: 'Ahora',
    );

    await ref.read(clientsProvider.notifier).addClient(newClient);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.pop();
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
                        label: 'Teléfono',
                        value: _phoneController.text,
                        onChanged: (v) => _phoneController.text = v,
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
                const SizedBox(height: 16),
                AppButton(
                  label: 'Guardar cliente',
                  fullWidth: true,
                  disabled: _nameController.text.trim().isEmpty,
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
