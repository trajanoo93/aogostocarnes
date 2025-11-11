// lib/screens/checkout/steps/step_payment.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/progress_timer.dart';

class StepPayment extends StatelessWidget {
  const StepPayment({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Column(
      children: [
        _QuickSummaryCard(),
        const SizedBox(height: 16),
        _PaymentOptionsCard(),
        const SizedBox(height: 16),
        if (c.paymentMethod == 'pix' && c.pixCode != null)
          _PixDigitavelCard(code: c.pixCode!, expiresAt: c.pixExpiresAt!),
        if (c.paymentMethod == 'money') _ChangeInfoCard(),
        if (c.paymentMethod == 'card-on-delivery') _CardOnDeliveryInfo(),
      ],
    );
  }
}

// === RESUMO RÁPIDO ===
class _QuickSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final address = c.addresses.firstWhere((a) => a.id == c.selectedAddressId, orElse: () => c.addresses.first);
    final pickup = c.pickupLocations[c.selectedPickup];

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF71717A), size: 20),
              const SizedBox(width: 8),
              Text(
                c.deliveryType == DeliveryType.delivery ? 'Entregar em' : 'Retirar em',
                style: const TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              TextButton(onPressed: c.prevStep, child: const Text('Alterar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.deliveryType == DeliveryType.delivery
                ? '${address.street}, ${address.number}'
                : pickup?['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// === OPÇÕES DE PAGAMENTO ===
class _PaymentOptionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final isOnline = c.storeDecision?.paymentMethods.any((m) => m['id'] == 'pix') ?? true;

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como Pagar?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 16),

          // === ONLINE ===
          if (isOnline) ...[
            const Text('Pagamentos Online', style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            _PaymentTile(
              icon: Icons.qr_code_2,
              title: 'PIX',
              subtitle: 'Pagamento rápido e seguro',
              active: c.paymentMethod == 'pix',
              onTap: () => c.paymentMethod = 'pix',
            ),
            const SizedBox(height: 12),
            _PaymentTile(
              icon: Icons.credit_card,
              title: 'Cartão de Crédito (Stripe)',
              subtitle: 'Em breve!',
              active: false,
              onTap: () {}, // ADICIONADO: onTap obrigatório
              disabled: true,
            ),
          ],

          const SizedBox(height: 24),

          // === NA ENTREGA ===
          const Text('Pagar na Entrega', style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          _ExpandablePaymentGroup(
            icon: Icons.local_shipping_outlined,
            title: 'Pagar na Entrega',
            subtitle: 'Dinheiro, Cartão ou Vale',
            isExpanded: ['money', 'card-on-delivery', 'voucher'].contains(c.paymentMethod),
            onToggle: () {
              if (!['money', 'card-on-delivery', 'voucher'].contains(c.paymentMethod)) {
                c.paymentMethod = 'money';
              }
            },
            children: [
              _PaymentTile(
                icon: Icons.payments,
                title: 'Dinheiro',
                active: c.paymentMethod == 'money',
                onTap: () => c.paymentMethod = 'money',
              ),
              const SizedBox(height: 12),
              _PaymentTile(
                icon: Icons.credit_card,
                title: 'Cartão na Entrega',
                active: c.paymentMethod == 'card-on-delivery',
                onTap: () => c.paymentMethod = 'card-on-delivery',
              ),
              const SizedBox(height: 12),
              _PaymentTile(
                icon: Icons.receipt_long,
                title: 'Vale Alimentação',
                active: c.paymentMethod == 'voucher',
                onTap: () => c.paymentMethod = 'voucher',
              ),
            ],
          ),
        ],
      ),
    );
  }
}



// === TILE DE PAGAMENTO ===
class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool active;
  final VoidCallback onTap;
  final bool disabled;
  final Widget? badge;

  const _PaymentTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.active,
    required this.onTap,
    this.disabled = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF7ED) : Colors.white,
          border: Border.all(color: active ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: disabled ? const Color(0xFF9CA3AF) : const Color(0xFFFA4815), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: disabled ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge!,
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? AppColors.primary : const Color(0xFFD4D4D8), width: 2),
                color: active ? AppColors.primary : Colors.white,
              ),
              child: active ? const Icon(Icons.circle, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// === GRUPO EXPANSÍVEL ===
class _ExpandablePaymentGroup extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _ExpandablePaymentGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  State<_ExpandablePaymentGroup> createState() => _ExpandablePaymentGroupState();
}

class _ExpandablePaymentGroupState extends State<_ExpandablePaymentGroup> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _height;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _height = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    if (widget.isExpanded) _anim.forward();
  }

  @override
  void didUpdateWidget(_ExpandablePaymentGroup old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      widget.isExpanded ? _anim.forward() : _anim.reverse();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: widget.onToggle,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: const Color(0xFFFA4815), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      Text(widget.subtitle, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded, size: 28, color: Color(0xFF71717A)),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _height,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: widget.children),
          ),
        ),
      ],
    );
  }
}

// === TROCO ===
class _ChangeInfoCard extends StatefulWidget {
  @override
  State<_ChangeInfoCard> createState() => _ChangeInfoCardState();
}

class _ChangeInfoCardState extends State<_ChangeInfoCard> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: c.needsChange,
                onChanged: (v) => setState(() => c.needsChange = v ?? false),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              const Text('Precisa de troco?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          if (c.needsChange)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Troco para quanto?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (v) => c.changeForAmount = v,
              ),
            ),
        ],
      ),
    );
  }
}

// === CARTÃO NA ENTREGA ===
class _CardOnDeliveryInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final total = c.total;
    final msg = total > 300
        ? 'Sua compra pode ser parcelada em até 3x.'
        : total > 200
            ? 'Sua compra pode ser parcelada em até 2x.'
            : 'Pagamento à vista na entrega.';
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Text(msg, style: const TextStyle(fontSize: 16)),
    );
  }
}

// === PIX DIGITÁVEL ===
class _PixDigitavelCard extends StatelessWidget {
  final String code;
  final DateTime expiresAt;
  const _PixDigitavelCard({required this.code, required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Pague com PIX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código PIX copiado!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ProgressTimer(expiresAt: expiresAt),
        ],
      ),
    );
  }
}

// === ESTILO COMUM ===
BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 2))],
    );