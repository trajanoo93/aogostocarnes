// lib/screens/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/models/order_models.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  static const statusSteps = ['Recebido', 'Em Preparo', 'A Caminho', 'Entregue'];

  @override
  Widget build(BuildContext context) {
    final activeIndex = statusSteps.indexOf(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalhes do Pedido #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === STATUS STEPS (CORRIGIDO) ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDeco(),
              child: Row(
                children: List.generate(statusSteps.length * 2 - 1, (index) {
                  final stepIndex = index ~/ 2;
                  final step = statusSteps[stepIndex];
                  final isActive = stepIndex == activeIndex;
                  final isDone = stepIndex <= activeIndex;

                  if (index.isEven) {
                    // ÍCONE + TEXTO
                    return Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? AppColors.primary : Colors.white,
                              border: Border.all(
                                color: isActive ? AppColors.primary : const Color(0xFFD4D4D8),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _getStatusIcon(step),
                                size: 20,
                                color: isDone ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive ? const Color(0xFF111827) : const Color(0xFF71717A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else {
                    // LINHA ENTRE ÍCONES
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? AppColors.primary : const Color(0xFFD4D4D8),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  }
                }),
              ),
            ),
            const SizedBox(height: 16),

            // === AVALIAÇÃO ===
            if (order.status == 'Entregue')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDeco(),
                child: Column(
                  children: [
                    const Text(
                      'Avalie sua experiência',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star,
                          color: (order.rating ?? 0) > i ? Colors.amber : Colors.grey[300],
                          size: 36,
                        );
                      }),
                    ),
                    if (order.rating != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Obrigado pela sua avaliação!',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // === ITENS DO PEDIDO (COM FALLBACK) ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Itens do Pedido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Divider(height: 32),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    'Qtd: ${item.quantity}',
                                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'R\$ ${(item.price * item.quantity).toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // === ENDEREÇO + PAGAMENTO ===
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDeco(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20, color: Color(0xFF71717A)),
                            const SizedBox(width: 8),
                            const Text('Endereço', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('${order.address.street}, ${order.address.number}'),
                        Text(order.address.neighborhood),
                        Text('${order.address.city} - ${order.address.state}'),
                        Text(order.address.cep),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDeco(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getPaymentIcon(order.payment.type),
                            const SizedBox(width: 8),
                            const Text('Pagamento', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(order.payment.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (order.payment.details != null)
                          Text(order.payment.details!, style: const TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // === RESUMO FINANCEIRO ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumo Financeiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Divider(height: 32),
                  _buildPriceRow('Subtotal', order.subtotal),
                  if (order.discount > 0) _buildPriceRow('Desconto', -order.discount, isDiscount: true),
                  _buildPriceRow('Taxa de Entrega', order.deliveryFee),
                  const Divider(height: 32),
                  _buildPriceRow('Total', order.total, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              color: isDiscount ? Colors.green[600] : const Color(0xFF71717A),
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}R\$ ${value.abs().toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              color: isDiscount ? Colors.green[600] : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Recebido':
        return Icons.check_circle;
      case 'Em Preparo':
        return Icons.inventory_2;
      case 'A Caminho':
        return Icons.local_shipping;
      case 'Entregue':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  Widget _getPaymentIcon(String type) {
    switch (type) {
      case 'PIX':
        return const Icon(Icons.qr_code_2, size: 24, color: Color(0xFF71717A));
      case 'Dinheiro':
        return const Icon(Icons.payments, size: 24, color: Color(0xFF71717A));
      case 'Cartão na Entrega':
        return const Icon(Icons.credit_card, size: 24, color: Color(0xFF71717A));
      default:
        return const Icon(Icons.payment, size: 24, color: Color(0xFF71717A));
    }
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      );
}