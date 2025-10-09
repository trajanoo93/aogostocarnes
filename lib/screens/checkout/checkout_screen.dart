// lib/screens/checkout/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aogosto_carnes_flutter/utils/app_colors.dart';
import 'package:aogosto_carnes_flutter/state/cart_controller.dart';
import 'package:aogosto_carnes_flutter/screens/checkout/checkout_controller.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutController()..bootstrapFromOnboarding(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> with TickerProviderStateMixin {
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();

    if (c.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Flow
          Visibility(
            visible: !c.orderPlaced,
            child: Column(
              children: [
                // Header + Stepper
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (c.currentStep == 1) Navigator.of(context).pop();
                                  else c.prevStep();
                                },
                                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3F3F46)),
                              ),
                              const SizedBox(width: 6),
                              const Text('Finalizar Compra',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _Stepper(current: c.currentStep, steps: const ['Onde e Quando?', 'Como Pagar?']),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
                    child: Column(
                      children: [
                        if (c.currentStep == 1) ...[
                          _OrderSummaryCard(),
                          const SizedBox(height: 14),
                          _ContactCard(),
                          const SizedBox(height: 14),
                          _DeliveryTypeCard(),
                          const SizedBox(height: 14),
                          if (c.deliveryType == DeliveryType.delivery) ...[
                            _AddressListCard(onChanged: c.refreshShippingFee),
                            const SizedBox(height: 14),
                            if (c.selectedAddressId != null)
                              _InfoRow(
                                icon: Icons.local_shipping_outlined,
                                label: 'Taxa de Entrega',
                                trailing: Text(
                                  _currency.format(c.deliveryFee),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                ),
                              ),
                          ] else ...[
                            _PickupListCard(),
                          ],
                          const SizedBox(height: 14),
                          _NotesCard(),
                        ] else ...[
                          _PaymentCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Success Screen
          if (c.orderPlaced) const _SuccessOverlay(),
        ],
      ),

      // Footer
      bottomNavigationBar: Visibility(
        visible: !c.orderPlaced,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Total', style: TextStyle(color: Color(0xFF52525B), fontWeight: FontWeight.w600, fontSize: 18)),
                    const Spacer(),
                    Text(
                      _currency.format(c.total),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => c.nextStep(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      c.currentStep == 1 ? 'Continuar para Pagamento' : 'Confirmar Pedido',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== Widgets ==========

class _Stepper extends StatelessWidget {
  final int current;
  final List<String> steps;
  const _Stepper({required this.current, required this.steps});

  @override
  Widget build(BuildContext context) {
    final active = AppColors.primary;
    const neutral = Color(0xFFD4D4D8);

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepDot(
            label: steps[i],
            number: i + 1,
            status: (current > i + 1)
                ? _StepStatus.done
                : (current == i + 1 ? _StepStatus.active : _StepStatus.idle),
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: current > i + 1 ? active : neutral,
              ),
            ),
        ]
      ],
    );
  }
}

enum _StepStatus { idle, active, done }

class _StepDot extends StatelessWidget {
  final String label;
  final int number;
  final _StepStatus status;
  const _StepDot({required this.label, required this.number, required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == _StepStatus.active;
    final isDone = status == _StepStatus.done;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 40 : 36,
          height: isActive ? 40 : 36,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : (isActive ? Colors.white : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: isActive ? 3 : 2,
            ),
            boxShadow: isActive
                ? [const BoxShadow(color: Color(0x14FA4815), blurRadius: 10, offset: Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.primary : const Color(0xFF6B7280),
                      fontSize: isActive ? 18 : 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFF18181B) : const Color(0xFF71717A),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatefulWidget {
  @override
  State<_OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends State<_OrderSummaryCard> with SingleTickerProviderStateMixin {
  bool expanded = false;
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final items = CartController.instance.items;

    return Container(
      decoration: _cardDeco(),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumo do Pedido', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        SizedBox(height: 6),
                        Text('Itens no carrinho', style: TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                      ],
                    ),
                  ),
                  Text(
                    _currency.format(c.total),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more_rounded, size: 28),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // itens
                      ...items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(it.product.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(it.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                      Text('Qtd: ${it.quantity}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Text(
                                  _currency.format(it.product.price * it.quantity),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 14),

                      // Cupom
                      _CouponArea(),
                      const SizedBox(height: 14),

                      // Totais
                      _TotalsArea(),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CouponArea extends StatelessWidget {
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  _CouponArea({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    if (c.appliedCoupon == null && !c.showCouponInput) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => c.showCoupon(),
          child: const Text('Adicionar cupom de desconto',
              style: TextStyle(color: Color(0xFFFA4815), fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      );
    }
    if (c.appliedCoupon == null && c.showCouponInput) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => c.couponCode = v,
                  decoration: const InputDecoration(
                    hintText: 'Digite seu cupom',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: c.isApplyingCoupon ? null : () => c.applyCoupon(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(c.isApplyingCoupon ? '...' : 'Aplicar', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          if (c.couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(c.couponError!, style: const TextStyle(color: Colors.red, fontSize: 14)),
            ),
        ],
      );
    }
    // aplicado
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(
            'Cupom aplicado: ${c.appliedCoupon!.code}',
            style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700, fontSize: 16),
          )),
          Text('- ${_currency.format(c.appliedCoupon!.discount)}',
              style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(width: 10),
          TextButton(
            onPressed: c.removeCoupon,
            child: const Text('Remover', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 16)),
          )
        ],
      ),
    );
  }
}

class _TotalsArea extends StatelessWidget {
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  _TotalsArea({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    return Column(
      children: [
        _KVRow('Subtotal', _currency.format(c.subtotal), fontSize: 16),
        if (c.appliedCoupon != null)
          _KVRow('Desconto', '- ${_currency.format(c.discount)}', color: const Color(0xFF16A34A), fontSize: 16),
        _KVRow(
          'Taxa de Entrega',
          _currency.format(c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0),
          fontSize: 16,
        ),
        const Divider(height: 26),
        _KVRow('Total', _currency.format(c.total), bold: true, big: true, fontSize: 20),
      ],
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool big;
  final Color? color;
  final double fontSize;

  const _KVRow(this.label, this.value,
      {this.bold = false, this.big = false, this.color, this.fontSize = 14, super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: big ? fontSize + 2 : fontSize,
      color: color ?? const Color(0xFF18181B),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Color(0xFF71717A), fontSize: fontSize)),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final controller = TextEditingController(text: c.userPhone);

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: c.isEditingPhone ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Telefone para contato', style: _h2),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [MaskTextInputFormatter(mask: '(##) #####-####')],
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_rounded, size: 24),
                hintText: '(00) 00000-0000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(14)),
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: c.setPhone,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: c.savePhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => c.cancelEditPhone(c.userPhone),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF3F3F46))),
                  ),
                ),
              ],
            ),
          ],
        ),
        secondChild: Row(
          children: [
            const Icon(Icons.phone_rounded, color: Color(0xFF71717A), size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.formatPhone(c.userPhone.isEmpty ? '—' : c.userPhone),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text('Usado para notificações do pedido.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              onPressed: c.startEditPhone,
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF71717A), size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryTypeCard extends StatelessWidget {
  const _DeliveryTypeCard();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final isDelivery = c.deliveryType == DeliveryType.delivery;

    Widget chip(String label, bool active, VoidCallback onTap, {String? emoji}) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFEDD5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: active ? AppColors.primary : const Color(0xFFD4D4D8), width: 2),
              boxShadow: [
                if (active) const BoxShadow(color: Color(0x14FA4815), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                '$emoji $label',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: active ? const Color(0xFF111827) : const Color(0xFF3F3F46),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como você quer receber?', style: _h2),
          const SizedBox(height: 14),
          Row(
            children: [
              chip('Entrega', isDelivery, () async {
                c.setDeliveryType(DeliveryType.delivery);
                await c.refreshShippingFee();
              }, emoji: '🚚'),
              const SizedBox(width: 14),
              chip('Retirada', !isDelivery, () {
                c.setDeliveryType(DeliveryType.pickup);
              }, emoji: '🏬'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressListCard extends StatelessWidget {
  final Future<void> Function() onChanged;
  const _AddressListCard({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();

    void _showAddressDialog({Address? addressToEdit}) {
      final streetCtrl = TextEditingController(text: addressToEdit?.street ?? '');
      final numberCtrl = TextEditingController(text: addressToEdit?.number ?? '');
      final complementCtrl = TextEditingController(text: addressToEdit?.complement ?? '');
      final neighborhoodCtrl = TextEditingController(text: addressToEdit?.neighborhood ?? '');
      final cityCtrl = TextEditingController(text: addressToEdit?.city ?? '');
      final stateCtrl = TextEditingController(text: addressToEdit?.state ?? '');
      final cepCtrl = TextEditingController(text: addressToEdit?.cep ?? '');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(addressToEdit == null ? 'Adicionar Endereço' : 'Editar Endereço'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(labelText: 'Rua'),
                ),
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Número'),
                ),
                TextField(
                  controller: complementCtrl,
                  decoration: const InputDecoration(labelText: 'Complemento (opcional)'),
                ),
                TextField(
                  controller: neighborhoodCtrl,
                  decoration: const InputDecoration(labelText: 'Bairro'),
                ),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                TextField(
                  controller: stateCtrl,
                  decoration: const InputDecoration(labelText: 'Estado (UF)'),
                ),
                TextField(
                  controller: cepCtrl,
                  decoration: const InputDecoration(labelText: 'CEP'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newAddress = Address(
                  id: addressToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  street: streetCtrl.text,
                  number: numberCtrl.text,
                  complement: complementCtrl.text.isEmpty ? null : complementCtrl.text,
                  neighborhood: neighborhoodCtrl.text,
                  city: cityCtrl.text,
                  state: stateCtrl.text,
                  cep: cepCtrl.text,
                );
                c.addOrUpdateAddress(newAddress);
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Endereço de Entrega', style: _h2),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: () => _showAddressDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: c.addresses.map((a) {
              final active = a.id == c.selectedAddressId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    c.selectAddress(a.id);
                    await onChanged();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFFF7ED) : Colors.white,
                      border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.shortLine,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                              Text('${a.neighborhood}, ${a.city} - ${a.state}',
                                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (active)
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF71717A), size: 20),
                              onPressed: () => _showAddressDialog(addressToEdit: a),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PickupListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Local de Retirada', style: _h2),
          const SizedBox(height: 12),
          Column(
            children: c.pickupLocations.entries.map((e) {
              final k = e.key;
              final loc = e.value;
              final active = k == c.selectedPickupKey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => c.selectPickup(k),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFFF7ED) : Colors.white,
                      border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                              Text(loc.address, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                            ],
                          ),
                        ),
                        if (active)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26)
                        else
                          const Icon(Icons.radio_button_off, color: Color(0xFF9CA3AF), size: 26),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 180),
        crossFadeState: c.showNotes ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Observações do Pedido', style: _h2),
            const SizedBox(height: 12),
            TextField(
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Ex.: Favor ligar quando chegar.',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: c.setOrderNotes,
            ),
          ],
        ),
        secondChild: Center(
          child: TextButton.icon(
            onPressed: c.toggleNotes,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
            label: const Text(
              'Adicionar observação (opcional)',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();

    List<PaymentOption> options = const [
      PaymentOption(id: 'credit-card', name: 'Cartão de Crédito (Stripe)', subtitle: 'Em breve!', disabled: true),
      PaymentOption(id: 'pix', name: 'PIX', subtitle: 'Pagamento rápido e seguro'),
      PaymentOption(id: 'money', name: 'Dinheiro', subtitle: 'Pague na entrega'),
      PaymentOption(id: 'card-on-delivery', name: 'Cartão na Entrega', subtitle: 'Débito ou Crédito'),
      PaymentOption(id: 'voucher', name: 'Vale Alimentação', subtitle: 'Alelo, Sodexo, Ticket'),
    ];

    Widget tile(PaymentOption o, bool active) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF7ED) : Colors.white,
          border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: o.disabled ? null : () => c.setPaymentMethod(o.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: o.disabled ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                            fontSize: 18,
                          )),
                      Text(o.subtitle, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: active ? AppColors.primary : const Color(0xFFD4D4D8),
                      width: 2,
                    ),
                    color: active ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: active
                      ? const Center(child: Icon(Icons.circle, size: 10, color: Colors.white))
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Forma de Pagamento', style: _h2),
          const SizedBox(height: 12),
          ...options.map((o) => Column(
                children: [
                  tile(o, c.paymentMethod == o.id),
                  if (c.paymentMethod == o.id) _PaymentDetails(method: o.id),
                ],
              )),
        ],
      ),
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  final String method;
  const _PaymentDetails({required this.method});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final NumberFormat currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    if (method == 'pix') {
      return _InfoBanner('Ao finalizar, o QR Code e o código Pix serão exibidos para pagamento.');
    }
    if (method == 'money') {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: c.needsChange,
                  onChanged: (v) => c.toggleNeedsChange(v ?? false),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Text('Precisa de troco?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            if (c.needsChange)
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Troco para quanto?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: c.setChangeAmount,
              ),
          ],
        ),
      );
    }
    if (method == 'card-on-delivery') {
      final total = c.total;
      final msg = (total > 300)
          ? 'Sua compra de ${currency.format(total)} pode ser parcelada em até 3x.'
          : (total > 200)
              ? 'Sua compra de ${currency.format(total)} pode ser parcelada em até 2x.'
              : 'Pagamento à vista no momento da entrega.';
      return _InfoBanner(msg);
    }
    if (method == 'voucher') {
      return _InfoBanner('Aceitamos: Alelo, Sodexo/Pluxee e Ticket.');
    }
    return const SizedBox.shrink();
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF52525B), fontSize: 14)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _InfoRow({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF71717A), size: 24),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final NumberFormat currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      color: const Color(0xFFF9FAFB),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, size: 90, color: Colors.green),
              const SizedBox(height: 14),
              Text('Pedido #${c.orderId ?? ''} Confirmado!',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'Seu pedido foi realizado com sucesso. Estamos preparando tudo para que sua experiência seja incrível!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF71717A), fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: _cardDeco(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _KVRow('Subtotal', currency.format(c.subtotal), fontSize: 16),
                    if (c.appliedCoupon != null)
                      _KVRow('Desconto', '- ${currency.format(c.discount)}',
                          color: const Color(0xFF16A34A), fontSize: 16),
                    _KVRow('Taxa de Entrega',
                        currency.format(c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0), fontSize: 16),
                    const Divider(height: 26),
                    _KVRow('Total', currency.format(c.total), bold: true, big: true, fontSize: 20),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Voltar para o Início',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ======= helpers visuais =======
const _h2 = TextStyle(fontWeight: FontWeight.w900, fontSize: 20);
BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 2)),
      ],
    );