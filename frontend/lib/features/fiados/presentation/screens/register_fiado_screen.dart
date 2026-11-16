import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiapp/core/theme/app_animations.dart';
import 'package:fiapp/core/theme/app_colors.dart';
import 'package:fiapp/core/utils/formatters.dart';
import 'package:fiapp/core/widgets/app_avatar.dart';
import 'package:fiapp/core/widgets/app_button.dart';
import 'package:fiapp/core/widgets/app_card.dart';
import 'package:fiapp/features/clients/domain/entities/client.dart';
import 'package:fiapp/features/clients/presentation/providers/clients_provider.dart';
import 'package:fiapp/features/fiados/domain/entities/fiado_item.dart';
import 'package:fiapp/features/history/presentation/providers/transactions_provider.dart';

/// Pantalla de registro de un nuevo fiado: formulario para agregar
/// productos, lista de productos agregados y total. Réplica de
/// `RegisterFiadoScreen` del prototipo original.
class RegisterFiadoScreen extends ConsumerStatefulWidget {
  final Client? client;

  const RegisterFiadoScreen({super.key, required this.client});

  @override
  ConsumerState<RegisterFiadoScreen> createState() => _RegisterFiadoScreenState();
}

class _RegisterFiadoScreenState extends ConsumerState<RegisterFiadoScreen> {
  final List<FiadoItem> _items = [];
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _nameFocus = FocusNode();

  String? _error;
  bool _success = false;

  /// Fecha de la venta (HU03 · T19). Por defecto, ahora mismo.
  DateTime? _saleDate;
  double _total = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  double get _currentTotal => _items.fold(0, (s, i) => s + i.subtotal);

  void _addItem() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 1;

    if (name.isEmpty) {
      setState(() => _error = 'Escribe el nombre del producto');
      return;
    }
    if (price <= 0) {
      setState(() => _error = 'Ingresa el precio unitario');
      return;
    }

    setState(() {
      _items.add(FiadoItem(id: Formatters.uid(), name: name, qty: qty, price: price));
      _nameController.clear();
      _qtyController.text = '1';
      _priceController.clear();
      _error = null;
    });
    _nameFocus.requestFocus();
  }

  void _removeItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
  }

  void _changeQuantity(int delta) {
    final current = int.tryParse(_qtyController.text) ?? 1;
    final next = (current + delta).clamp(1, 999);
    setState(() => _qtyController.text = next.toString());
  }

  Future<void> _handleSave() async {
    if (_items.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto');
      return;
    }
    final client = widget.client;
    if (client == null) return;

    final total = _currentTotal;
    final newBalance = client.balance + total;
    try {
      await ref.read(transactionsProvider.notifier).registerFiado(
            clientId: client.id,
            items: _items,
            newBalanceAfter: newBalance,
            date: _saleDate,
          );
      await ref.read(clientsProvider.notifier).refreshClient(client.id);
      if (!mounted) return;
      setState(() {
        _success = true;
        _total = total;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo registrar el fiado: $error';
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final updatedClient = ref.read(clientsProvider.notifier).findById(client.id);
    context.pop();
    if (updatedClient != null) {
      context.push('/client-detail', extra: updatedClient);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'Fecha de la venta',
    );
    if (picked == null || !mounted) return;
    final isToday = DateUtils.isSameDay(picked, now);
    setState(() {
      // Hoy: se usa la hora actual. Otro día: mediodía, para evitar saltos de zona horaria.
      _saleDate = isToday ? null : DateTime(picked.year, picked.month, picked.day, 12);
    });
  }

  String get _saleDateLabel {
    final date = _saleDate;
    if (date == null) return 'Hoy';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;

    if (_success) {
      return _SuccessView(total: _total, clientName: client?.name ?? '');
    }

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Registrar fiado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  if (client != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppAvatar(client: client, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            client.name.split(' ').first,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                AppCard(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 20, color: AppColors.blue),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Fecha de la venta',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, fontFamily: 'Inter'),
                        ),
                      ),
                      Text(
                        _saleDateLabel,
                        style: const TextStyle(fontSize: 14, color: AppColors.blue, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AGREGAR PRODUCTO',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted, fontFamily: 'Inter', letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        onSubmitted: (_) => _addItem(),
                        decoration: const InputDecoration(hintText: 'Nombre del producto'),
                        style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 42,
                              child: IconButton(
                                onPressed: () => _changeQuantity(-1),
                                icon: const Icon(Icons.remove, size: 18),
                                splashRadius: 20,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Cant.',
                                ),
                                style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                              ),
                            ),
                            SizedBox(
                              width: 42,
                              child: IconButton(
                                onPressed: () => _changeQuantity(1),
                                icon: const Icon(Icons.add, size: 18),
                                splashRadius: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Precio unitario'),
                        style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12, fontFamily: 'Inter')),
                        ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Agregar producto',
                        icon: const Icon(Icons.add, size: 16),
                        fullWidth: true,
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_items.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'PRODUCTOS (${_items.length})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, fontFamily: 'Inter', letterSpacing: 0.5),
                    ),
                  ),
                  ..._items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink, fontFamily: 'Inter'),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.qty} × ${Formatters.currency(item.price)}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFamily: 'Inter'),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.currency(item.subtotal),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'Inter'),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => _removeItem(item.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.redLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.close, size: 14, color: AppColors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text('🛒', style: TextStyle(fontSize: 28)),
                        SizedBox(height: 8),
                        Text(
                          'Agrega los productos del fiado',
                          style: TextStyle(color: AppColors.muted, fontFamily: 'Inter', fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total del fiado',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.muted, fontFamily: 'Inter'),
                    ),
                    Text(
                      Formatters.currency(_currentTotal),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter', letterSpacing: -0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Guardar fiado',
                  fullWidth: true,
                  disabled: _items.isEmpty,
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
  final double total;
  final String clientName;

  const _SuccessView({required this.total, required this.clientName});

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
                child: const Icon(Icons.check_circle_outline, size: 46, color: AppColors.green),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Text(
                    '¡Fiado registrado!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, fontFamily: 'Inter', letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se registraron ${Formatters.currency(total)} a $clientName',
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
