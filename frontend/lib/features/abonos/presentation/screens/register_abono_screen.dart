import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_animations.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_avatar.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/core/widgets/app_input.dart';
import 'package:fiapp/core/widgets/app_top_bar.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';
import 'package:fiapp/features/history/presentation/providers/transactions_provider.dart';

/// Pantalla de registro de un abono (pago recibido). Réplica de
/// `RegisterAbonoScreen` del prototipo original: monto, método de pago
/// (chips seleccionables) y observaciones.
class RegisterAbonoScreen extends ConsumerStatefulWidget {
  final Client? client;

  const RegisterAbonoScreen({super.key, required this.client});

  @override
  ConsumerState<RegisterAbonoScreen> createState() => _RegisterAbonoScreenState();
}

class _RegisterAbonoScreenState extends ConsumerState<RegisterAbonoScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _method = 'Efectivo';
  bool _success = false;

  static const _methods = ['Efectivo', 'Transferencia', 'Nequi', 'Daviplata', 'Otro'];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  Future<void> _handleSave() async {
    final client = widget.client;
    if (_amount <= 0 || client == null) return;

    setState(() => _success = true);

    final newBalance = (client.balance - _amount).clamp(0, double.infinity).toDouble();
    await ref.read(transactionsProvider.notifier).registerAbono(
          clientId: client.id,
          amount: _amount,
          paymentMethod: _method,
          note: _noteController.text,
          newBalanceAfter: newBalance,
        );
    await ref.read(clientsProvider.notifier).refreshClient(client.id);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final updatedClient = ref.read(clientsProvider.notifier).findById(client.id);
    context.pop();
    if (updatedClient != null) {
      context.push('/client-detail', extra: updatedClient);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;

    if (_success) {
      return _SuccessView(amount: _amount, clientName: client?.name ?? '');
    }

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          AppTopBar(title: 'Registrar abono', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (client != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      backgroundColor: AppColors.blueLight,
                      noShadow: true,
                      border: Border.all(color: AppColors.blue.withValues(alpha: 0.13)),
                      child: Row(
                        children: [
                          AppAvatar(client: client, size: 44),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'Inter'),
                              ),
                              const SizedBox(height: 3),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'Inter'),
                                  children: [
                                    const TextSpan(text: 'Saldo pendiente: '),
                                    TextSpan(
                                      text: Formatters.currency(client.balance),
                                      style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Valor pagado *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: '0',
                          prefixText: r'$ ',
                          prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.green, fontFamily: 'Inter'),
                        ),
                      ),
                      if (client != null && _amount > 0 && _amount <= client.balance)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Saldo restante: ${Formatters.currency(client.balance - _amount)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFamily: 'Inter'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Método de pago',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _methods.map((m) {
                          final selected = _method == m;
                          return GestureDetector(
                            onTap: () => setState(() => _method = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.blueLight : AppColors.bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selected ? AppColors.blue : AppColors.border, width: 1.5),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  color: selected ? AppColors.blue : AppColors.muted,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Observaciones',
                        value: _noteController.text,
                        onChanged: (v) => _noteController.text = v,
                        placeholder: 'Nota opcional...',
                        multiline: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Registrar abono',
                  fullWidth: true,
                  variant: AppButtonVariant.green,
                  disabled: _amount <= 0,
                  icon: const Icon(Icons.check, size: 16),
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
  final double amount;
  final String clientName;

  const _SuccessView({required this.amount, required this.clientName});

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
                width: 90,
                height: 90,
                decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 46, color: AppColors.green),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Text(
                    '¡Abono registrado!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Formatters.currency(amount)} recibidos de $clientName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.muted, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
