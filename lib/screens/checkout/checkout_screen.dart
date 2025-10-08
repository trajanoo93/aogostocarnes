import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aogosto_carnes_flutter/utils/app_colors.dart';
import 'package:aogosto_carnes_flutter/state/cart_controller.dart';
import 'package:aogosto_carnes_flutter/screens/checkout/checkout_controller.dart';

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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                              const SizedBox(width: 4),
                              const Text('Finalizar Compra',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _Stepper(current: c.currentStep, steps: const ['Onde e Quando?', 'Como Pagar?']),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      children: [
                        if (c.currentStep == 1) ...[
                          _OrderSummaryCard(),
                          const SizedBox(height: 12),
                          _ContactCard(),
                          const SizedBox(height: 12),
                          _DeliveryTypeCard(),
                          const SizedBox(height: 12),
                          if (c.deliveryType == DeliveryType.delivery) ...[
                            _AddressListCard(onChanged: c.refreshShippingFee),
                            const SizedBox(height: 12),
                            if (c.selectedAddressId != null)
                              _InfoRow(
                                icon: Icons.local_shipping_outlined,
                                label: 'Taxa de Entrega',
                                trailing: Text(
                                  _currency.format(c.deliveryFee),
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                          ] else ...[
                            _PickupListCard(),
                          ],
                          const SizedBox(height: 12),
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Total', style: TextStyle(color: Color(0xFF52525B), fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _currency.format(c.total),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => c.nextStep(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      c.currentStep == 1 ? 'Continuar para Pagamento' : 'Confirmar Pedido',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
                margin: const EdgeInsets.symmetric(horizontal: 12),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : (isActive ? Colors.white : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.primary : const Color(0xFF6B7280),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFF18181B) : const Color(0xFF71717A),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumo do Pedido', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Itens no carrinho', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    _currency.format(c.total),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more_rounded),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // itens
                      ...items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(it.product.imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(it.product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w800)),
                                      Text('Qtd: ${it.quantity}', style: const TextStyle(color: Color(0xFF71717A))),
                                    ],
                                  ),
                                ),
                                Text(
                                  _currency.format(it.product.price * it.quantity),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),

                      // Cupom
                      _CouponArea(),
                      const SizedBox(height: 12),

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
              style: TextStyle(color: Color(0xFFFA4815), fontWeight: FontWeight.w900)),
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
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: c.isApplyingCoupon ? null : () => c.applyCoupon(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(c.isApplyingCoupon ? '...' : 'Aplicar'),
              ),
            ],
          ),
          if (c.couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(c.couponError!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      );
    }
    // aplicado
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(
            'Cupom aplicado: ${c.appliedCoupon!.code}',
            style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700),
          )),
          Text('- ${_currency.format(c.appliedCoupon!.discount)}',
              style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          TextButton(
            onPressed: c.removeCoupon,
            child: const Text('Remover', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
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
        _KVRow('Subtotal', _currency.format(c.subtotal)),
        if (c.appliedCoupon != null)
          _KVRow('Desconto', '- ${_currency.format(c.discount)}', color: const Color(0xFF16A34A)),
        _KVRow(
          'Taxa de Entrega',
          _currency.format(c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0),
        ),
        const Divider(height: 24),
        _KVRow('Total', _currency.format(c.total), bold: true, big: true),
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

  const _KVRow(this.label, this.value, {this.bold = false, this.big = false, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: big ? 18 : 14,
      color: color ?? const Color(0xFF18181B),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF71717A))),
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
      padding: const EdgeInsets.all(16),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: c.isEditingPhone ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Telefone para contato', style: _h2),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_rounded),
                hintText: '(00) 00000-0000',
                border: OutlineInputBorder(),
              ),
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
                    ),
                    child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => c.cancelEditPhone(c.userPhone),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            )
          ],
        ),
        secondChild: Row(
          children: [
            const Icon(Icons.phone_rounded, color: Color(0xFF71717A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.userPhone.isEmpty ? '—' : c.userPhone,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 2),
                  const Text('Usaremos esse número para atualizações do pedido.',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: c.startEditPhone,
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF71717A)),
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
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFEDD5) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? AppColors.primary : const Color(0xFFD4D4D8), width: 2),
              boxShadow: [
                if (active) const BoxShadow(color: Color(0x14FA4815), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Text(
                '${emoji ?? ''} $label',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: active ? const Color(0xFF111827) : const Color(0xFF3F3F46),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como você quer receber?', style: _h2),
          const SizedBox(height: 12),
          Row(
            children: [
              chip('Receber em Casa', isDelivery, () async {
                c.setDeliveryType(DeliveryType.delivery);
                await c.refreshShippingFee();
              }, emoji: '🏠'),
              const SizedBox(width: 12),
              chip('Retirar na Loja', !isDelivery, () {
                c.setDeliveryType(DeliveryType.pickup);
              }, emoji: '🛵'),
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

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Endereço de Entrega', style: _h2),
          const SizedBox(height: 10),
          Column(
            children: c.addresses.map((a) {
              final active = a.id == c.selectedAddressId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () async {
                    c.selectAddress(a.id);
                    await onChanged();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFFF7ED) : Colors.white,
                      border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.shortLine,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('${a.neighborhood}, ${a.city} - ${a.state}',
                                  style: const TextStyle(color: Color(0xFF71717A))),
                            ],
                          ),
                        ),
                        if (active)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        else
                          const Icon(Icons.radio_button_off, color: Color(0xFF9CA3AF)),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Local de Retirada', style: _h2),
          const SizedBox(height: 10),
          Column(
            children: c.pickupLocations.entries.map((e) {
              final k = e.key;
              final loc = e.value;
              final active = k == c.selectedPickupKey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => c.selectPickup(k),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFFF7ED) : Colors.white,
                      border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              Text(loc.address, style: const TextStyle(color: Color(0xFF71717A))),
                            ],
                          ),
                        ),
                        if (active)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        else
                          const Icon(Icons.radio_button_off, color: Color(0xFF9CA3AF)),
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
      padding: const EdgeInsets.all(16),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 180),
        crossFadeState: c.showNotes ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Observações do Pedido', style: _h2),
            const SizedBox(height: 10),
            TextField(
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Ex.: Carne ao ponto, por favor.',
                border: OutlineInputBorder(),
              ),
              onChanged: c.setOrderNotes,
            ),
          ],
        ),
        secondChild: Center(
          child: TextButton.icon(
            onPressed: c.toggleNotes,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            label: const Text(
              'Adicionar observação (opcional)',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF7ED) : Colors.white,
          border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: o.disabled ? null : () => c.setPaymentMethod(o.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                          )),
                      Text(o.subtitle, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: active ? AppColors.primary : const Color(0xFFD4D4D8),
                      width: 2,
                    ),
                    color: active ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: active
                      ? const Center(child: Icon(Icons.circle, size: 8, color: Colors.white))
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Forma de Pagamento', style: _h2),
          const SizedBox(height: 10),
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
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: c.needsChange,
                  onChanged: (v) => c.toggleNeedsChange(v ?? false),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text('Precisa de troco?', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            if (c.needsChange)
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Troco para quanto?',
                  border: OutlineInputBorder(),
                ),
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
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF52525B), fontSize: 12)),
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF71717A)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
              const SizedBox(height: 12),
              const Text('Pedido Confirmado!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Seu pedido foi realizado com sucesso. Estamos preparando tudo para que sua experiência seja incrível!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: _cardDeco(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _KVRow('Subtotal', currency.format(c.subtotal)),
                    if (c.appliedCoupon != null)
                      _KVRow('Desconto', '- ${currency.format(c.discount)}',
                          color: const Color(0xFF16A34A)),
                    _KVRow('Taxa de Entrega',
                        currency.format(c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0)),
                    const Divider(height: 24),
                    _KVRow('Total', currency.format(c.total), bold: true, big: true),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Voltar para o Início',
                      style: TextStyle(fontWeight: FontWeight.w900)),
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
const _h2 = TextStyle(fontWeight: FontWeight.w900, fontSize: 18);
BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(16),
    );
