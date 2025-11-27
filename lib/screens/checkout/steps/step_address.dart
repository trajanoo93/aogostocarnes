// lib/screens/checkout/steps/step_address.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';     
import 'package:ao_gosto_app/models/customer_data.dart';       
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/calendar_widget.dart';
import 'package:ao_gosto_app/screens/checkout/widgets/time_slot_grid.dart';
import 'package:ao_gosto_app/screens/profile/widgets/address_form_sheet.dart'; 

class StepAddress extends StatelessWidget {
  const StepAddress({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final customerProv = context.watch<CustomerProvider>();
    final customer = customerProv.customer;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    // Se ainda não carregou o cliente, mostra loading
    if (customer == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Pega endereços do Firestore
    final addresses = customer.addresses;

    return Column(
      children: [
        _OrderSummaryCard(),
        const SizedBox(height: 16),
        _ContactCard(),
        const SizedBox(height: 16),
        _DeliveryTypeCard(),
        const SizedBox(height: 16),
        if (c.deliveryType == DeliveryType.delivery) ...[
          _AddressListCard(addresses: addresses, checkoutController: c),
          if (c.selectedAddressId != null && c.deliveryFee > 0)
            _DeliveryFeeRow(fee: c.deliveryFee),
        ] else
          _PickupListCard(),
        const SizedBox(height: 16),
        _ScheduleCard(),
        const SizedBox(height: 16),
        _NotesCard(),
        const SizedBox(height: 100),
      ],
    );
  }
}

// === LISTA DE ENDEREÇOS (AGORA DO FIRESTORE) ===
class _AddressListCard extends StatelessWidget {
  final List<CustomerAddress> addresses;
  final CheckoutController checkoutController;

  const _AddressListCard({required this.addresses, required this.checkoutController});

  @override
  Widget build(BuildContext context) {
    final c = checkoutController;

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Endereço de Entrega', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: () => _showAddressSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Nenhum endereço cadastrado', style: TextStyle(color: Colors.grey)),
            )
          else
            ...addresses.map((addr) {
              final isSelected = addr.id == c.selectedAddressId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    c.selectAddress(addr.id);
                    c.refreshFee();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                      border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(addr.apelido, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  if (addr.isDefault)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Padrão', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${addr.street}, ${addr.number}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('${addr.neighborhood}, ${addr.city} - ${addr.state}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                            ],
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// === BOTÃO ADICIONAR ENDEREÇO (reutiliza seu AddressFormSheet) ===
void _showAddressSheet(BuildContext context) {
  final provider = Provider.of<CustomerProvider>(context, listen: false);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddressFormSheet(
      onSave: (data) async {
        final novoEndereco = CustomerAddress(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          apelido: data['apelido'] ?? 'Endereço',
          street: data['street'],
          number: data['number'],
          complement: data['complement'],
          neighborhood: data['neighborhood'],
          city: data['city'],
          state: data['state'],
          cep: data['cep'],
          isDefault: provider.customer?.addresses.isEmpty ?? true,
        );

        await provider.saveAddress(novoEndereco, setAsDefault: novoEndereco.isDefault);
        Navigator.pop(context);
      },
    ),
  );
}

// === RESUMO DO PEDIDO ===
class _OrderSummaryCard extends StatefulWidget {
  @override
  State<_OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends State<_OrderSummaryCard> {
  bool expanded = false;
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resumo do Pedido', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('${items.length} itens', style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                      ],
                    ),
                  ),
                  Text(currency.format(c.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, size: 28, color: Color(0xFF71717A)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ...items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(it.product.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  Text('Qtd: ${it.quantity}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                                ],
                              ),
                            ),
                            Text(currency.format(it.product.price * it.quantity), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _CouponArea(),
                  const SizedBox(height: 16),
                  _TotalsArea(),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// === CUPOM ===
class _CouponArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    if (c.appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFEFFAF1), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: Text('Cupom aplicado: ${c.appliedCoupon!.code}', style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700, fontSize: 16))),
            Text('- ${NumberFormat.simpleCurrency(locale: 'pt_BR').format(c.appliedCoupon!.discount)}', style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 8),
            TextButton(onPressed: c.removeCoupon, child: const Text('Remover', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 16))),
          ],
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => _showCouponDialog(context),
        child: const Text('Adicionar cupom de desconto', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }
}

void _showCouponDialog(BuildContext context) {
  final c = context.read<CheckoutController>();
  final ctrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cupom de Desconto'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'EX: BEMVINDO10')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () { c.applyCoupon(ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('Aplicar')),
      ],
    ),
  );
}

// === TOTAIS ===
class _TotalsArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Column(
      children: [
        _KVRow('Subtotal', currency.format(c.subtotal)),
        _KVRow('Taxa de Entrega', currency.format(c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0)),
        const Divider(height: 26),
        _KVRow('Total', currency.format(c.total), bold: true, big: true),
      ],
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label, value;
  final bool bold, big;
  const _KVRow(this.label, this.value, {this.bold = false, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 16)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, fontSize: big ? 20 : 16)),
        ],
      ),
    );
  }
}

// === CONTATO (TELEFONE) — INSTANTÂNEO ===
class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: c.isEditingPhone
          ? _PhoneEditForm()
          : Row(
              children: [
                const Icon(Icons.phone_rounded, color: Color(0xFF71717A), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.formatPhone(c.userPhone.isEmpty ? '—' : c.userPhone), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const Text('Usado para notificações.', style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                    ],
                  ),
                ),
                // BOTÃO INSTANTÂNEO
                GestureDetector(
                  onTap: c.startEditPhone,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF71717A), size: 20),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PhoneEditForm extends StatefulWidget {
  @override
  State<_PhoneEditForm> createState() => _PhoneEditFormState();
}

class _PhoneEditFormState extends State<_PhoneEditForm> {
  late final TextEditingController ctrl;
  final formatter = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    final c = context.read<CheckoutController>();
    ctrl = TextEditingController(text: c.formatPhone(c.userPhone));
    ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.read<CheckoutController>();
    final raw = formatter.getUnmaskedText();
    final isValid = raw.length >= 10;

    return Column(
      children: [
        TextField(
          controller: ctrl,
          inputFormatters: [formatter],
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '(00) 00000-0000', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isValid
                    ? () async {
                        await c.savePhone(raw);
                        if (mounted) setState(() {});
                      }
                    : null,
                child: const Text('Salvar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: c.cancelEditPhone, child: const Text('Cancelar'))),
          ],
        ),
      ],
    );
  }
}

// === TIPO DE ENTREGA ===
class _DeliveryTypeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Como você quer receber?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _DeliveryChip(label: 'Receber em Casa', emoji: '🛵', active: c.deliveryType == DeliveryType.delivery, onTap: () => c.setDeliveryType(DeliveryType.delivery))),
              const SizedBox(width: 16),
              Expanded(child: _DeliveryChip(label: 'Retirar na Loja', emoji: '🏠', active: c.deliveryType == DeliveryType.pickup, onTap: () => c.setDeliveryType(DeliveryType.pickup))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryChip extends StatelessWidget {
  final String label, emoji;
  final bool active;
  final VoidCallback onTap;
  const _DeliveryChip({required this.label, required this.emoji, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFEDD5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.primary : const Color(0xFFD4D4D8), width: 2),
          boxShadow: active ? [const BoxShadow(color: Color(0x14FA4815), blurRadius: 10, offset: Offset(0, 4))] : [],
        ),
        child: Center(child: Text('$emoji $label', style: TextStyle(fontWeight: FontWeight.w900, color: active ? const Color(0xFF111827) : const Color(0xFF3F3F46), fontSize: 16))),
      ),
    );
  }
}


// === TAXA DE ENTREGA ===
class _DeliveryFeeRow extends StatelessWidget {
  final double fee;
  const _DeliveryFeeRow({required this.fee});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined, color: Color(0xFF71717A), size: 28),
          const SizedBox(width: 16),
          const Text('Taxa de Entrega', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const Spacer(),
          Text(currency.format(fee), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}

// === RETIRADA EM LOJA ===
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
          const Text('Local de Retirada', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 12),
          ...c.pickupLocations.entries.map((e) {
            final key = e.key;
            final loc = e.value;
            final active = key == c.selectedPickup;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => c.selectPickup(key),
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
                            Text(loc['name']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            Text(loc['address']!, style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                          ],
                        ),
                      ),
                      if (active) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// === AGENDAMENTO — MODAL + 2 SLOTS POR LINHA ===
class _ScheduleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final dateStr = c.selectedTimeSlot == null
        ? 'Selecione uma data'
        : '${c.selectedDate.day.toString().padLeft(2, '0')}/${c.selectedDate.month.toString().padLeft(2, '0')}';

    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agende sua Entrega', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 16),

          // === DATA (INPUT ESTILO) ===
          InkWell(
            onTap: () => _showCalendarModal(context, c),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF71717A), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: c.selectedTimeSlot == null ? const Color(0xFF9CA3AF) : const Color(0xFF18181B),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF71717A)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // === SLOTS (2 POR LINHA) ===
        // === SLOTS (2 POR LINHA) ===
if (c.getTimeSlots().isNotEmpty)
  TimeSlotGrid(
    slots: c.getTimeSlots(),
    selectedSlot: c.selectedTimeSlot,
    onSlotSelected: (slot) {
      c.selectedTimeSlot = slot;
      c.notifyListeners();
    },
  )
else
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text(
      'Loja fechada neste dia',
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
    ),
  ),
          // === RESUMO ===
          if (c.selectedTimeSlot != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFAF1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF16A34A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Agendado: $dateStr • ${c.selectedTimeSlot}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void _showCalendarModal(BuildContext context, CheckoutController c) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.7,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Selecione a Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Expanded(child: CalendarWidget(selectedDate: c.selectedDate, onDateSelected: (date) { c.selectedDate = date; c.selectedTimeSlot = null; c.notifyListeners(); Navigator.pop(ctx); })),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

// === OBSERVAÇÕES ===
class _NotesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: c.orderNotes.isEmpty
          ? Center(
              child: TextButton.icon(
                onPressed: () => _showNotesDialog(context),
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                label: const Text('Adicionar observação (opcional)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Observações do Pedido', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    IconButton(
                      onPressed: () => _showNotesDialog(context),
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF71717A), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(c.orderNotes, style: const TextStyle(fontSize: 16)),
              ],
            ),
    );
  }
}

void _showNotesDialog(BuildContext context) {
  final c = context.read<CheckoutController>();
  final ctrl = TextEditingController(text: c.orderNotes);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Observações'),
      content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Ex: Favor buzinar ao chegar')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () { c.orderNotes = ctrl.text; Navigator.pop(ctx); }, child: const Text('Salvar')),
      ],
    ),
  );
}

// === ESTILO COMUM ===
BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 2))],
    );