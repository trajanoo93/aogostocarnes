// lib/screens/checkout/thank_you_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final address = c.addresses.firstWhere((a) => a.id == c.selectedAddressId, orElse: () => c.addresses.first);
    final pickup = c.pickupLocations[c.selectedPickup];

    final whatsappMessage = Uri.encodeComponent(
      'Oi! Fiz um pedido no app (#${c.orderId}) e tenho uma dúvida. Pode me ajudar?',
    );
    final whatsappUrl = 'https://wa.me/553134613297?text=$whatsappMessage';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            children: [
              // === ÍCONE DE SUCESSO ===
              const Icon(Icons.check_circle_rounded, size: 90, color: Colors.green),
              const SizedBox(height: 16),

              // === TÍTULO + NÚMERO DO PEDIDO ===
              Text('Pedido #${c.orderId}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'Seu pedido foi realizado com sucesso. Estamos preparando tudo para que sua experiência seja incrível!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF71717A), fontSize: 16),
              ),
              const SizedBox(height: 24),

              // === RESUMO DO PEDIDO ===
              Container(
                decoration: _cardDeco(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SummaryRow('Subtotal', currency.format(c.subtotal)),
                    _SummaryRow('Taxa de Entrega', currency.format(c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0)),
                    const Divider(height: 26),
                    _SummaryRow('Total', currency.format(c.total), bold: true, big: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // === DETALHES DA ENTREGA/RETIRADA ===
              Container(
                decoration: _cardDeco(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.deliveryType == DeliveryType.delivery ? 'Entrega' : 'Retirada',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF16A34A), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.deliveryType == DeliveryType.delivery
                                ? 'Será entregue em:'
                                : 'Pronto para retirada em:',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.deliveryType == DeliveryType.delivery
                                ? '${address.street}, ${address.number}\n${address.neighborhood}, ${address.city} - ${address.state}'
                                : '${pickup?['name']}\n${pickup?['address']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (c.deliveryType == DeliveryType.pickup)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Por favor, apresente o número do seu pedido ao chegar.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // === OBSERVAÇÕES (SE HOUVER) ===
              if (c.orderNotes.isNotEmpty)
                Container(
                  decoration: _cardDeco(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.note_alt_outlined, color: Color(0xFF71717A), size: 24),
                          SizedBox(width: 12),
                          Text('Observações', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          '"${c.orderNotes}"',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // === BOTÕES DE AÇÃO ===
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(whatsappUrl)),
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text('Falar no WhatsApp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Voltar para o Início', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold, big;
  const _SummaryRow(this.label, this.value, {this.bold = false, this.big = false});

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

BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 2))],
    );