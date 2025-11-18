// lib/screens/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ao_gosto_app/models/order_model.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';

class OrderDetailScreen extends StatefulWidget {
  final AppOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int? _userRating;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _userRating = widget.order.rating;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${date.day} ${months[date.month - 1]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitRating(int rating) async {
    setState(() {
      _isSubmittingRating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(widget.order.id)
          .update({'rating': rating});

      setState(() {
        _userRating = rating;
        _isSubmittingRating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Obrigado pela sua avaliação!',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmittingRating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao enviar avaliação. Tente novamente.',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  int _getStatusIndex(String status) {
    final statusOrder = ['Recebido', 'Montado', 'Saiu pra Entrega', 'Concluído'];
    // Compatibilidade com nomes antigos
    if (status == 'Registrado') return 1;
    if (status == 'Em Preparo') return 1;
    if (status == 'A Caminho') return 2;
    if (status == 'Entregue') return 3;

    final index = statusOrder.indexOf(status);
    return index != -1 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentStatusIndex = _getStatusIndex(widget.order.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[900]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalhes do Pedido #${widget.order.id}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS TRACKER MODERNO
            _buildModernStatusTracker(currentStatusIndex),

            const SizedBox(height: 32),

            // AVALIAÇÃO
            if (widget.order.status == 'Concluído' || widget.order.status == 'Entregue')
              _buildRatingSection(),

            if (widget.order.status == 'Concluído' || widget.order.status == 'Entregue')
              const SizedBox(height: 24),

            // ITENS DO PEDIDO
            _buildSection(
              title: 'Itens do Pedido',
              child: Column(
                children: widget.order.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == widget.order.items.length - 1;

                  return Column(
                    children: [
                      _buildOrderItem(item),
                      if (!isLast) Divider(height: 24, color: Colors.grey[200]),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ENDEREÇO E PAGAMENTO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSection(
                    title: 'Endereço',
                    icon: Icons.location_on_outlined,
                    child: Text(
                      '${widget.order.address.street}, ${widget.order.address.number}\n'
                      '${widget.order.address.complement.isNotEmpty ? '${widget.order.address.complement}\n' : ''}'
                      '${widget.order.address.neighborhood}\n'
                      '${widget.order.address.city} - ${widget.order.address.state}\n'
                      '${widget.order.address.cep}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSection(
                    title: 'Pagamento',
                    icon: Icons.credit_card_outlined,
                    child: Text(
                      widget.order.payment.type == 'unknown'
                          ? 'Não informado'
                          : _formatPaymentType(widget.order.payment.type),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // RESUMO DO PEDIDO
            _buildSection(
              title: 'Resumo',
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', widget.order.subtotal),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Taxa de entrega', widget.order.deliveryFee),
                  if (widget.order.discount > 0) ...[
                    const SizedBox(height: 12),
                    _buildSummaryRow('Desconto', -widget.order.discount, isDiscount: true),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Total', widget.order.total, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatusTracker(int currentIndex) {
    final statuses = [
      ('Recebido', Icons.shopping_bag_rounded),
      ('Montado', Icons.inventory_2_rounded),
      ('Saiu pra Entrega', Icons.two_wheeler_rounded),
      ('Concluído', Icons.check_circle_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          // Ícones e linhas
          Row(
            children: List.generate(statuses.length, (index) {
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final status = statuses[index];

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          // Ícone
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isCurrent ? 64 : (isActive ? 48 : 40),
                            height: isCurrent ? 64 : (isActive ? 48 : 40),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status.$2,
                              color: isActive ? Colors.white : Colors.grey[400],
                              size: isCurrent ? 32 : (isActive ? 24 : 20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Linha conectora CINZA
                    if (index < statuses.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 0),
                          color: isActive
                              ? Colors.grey[300]
                              : Colors.grey[200],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Status atual - MINIMALISTA (apenas texto simples)
          Text(
            statuses[currentIndex].$1,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            _userRating != null
                ? 'Sua avaliação'
                : 'Avalie sua experiência',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = _userRating != null && starValue <= _userRating!;

              return GestureDetector(
                onTap: _isSubmittingRating ? null : () => _submitRating(starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: 40,
                    color: isSelected ? Colors.amber : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
          if (_isSubmittingRating) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    IconData? icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.restaurant,
                      color: Colors.grey[400],
                    ),
                  ),
                )
              : Icon(Icons.restaurant, color: Colors.grey[400]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              Text(
                'Qtd: ${item.quantity}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          'R\$ ${(item.price * item.quantity).toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: Colors.grey[isTotal ? 900 : 600],
          ),
        ),
        Text(
          'R\$ ${value.abs().toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            color: isDiscount
                ? Colors.green
                : (isTotal ? AppColors.primary : Colors.grey[900]),
          ),
        ),
      ],
    );
  }

  String _formatPaymentType(String type) {
    if (type.toLowerCase().contains('pix')) return 'Pix';
    if (type.toLowerCase().contains('card') || type.toLowerCase().contains('cartão')) return 'Cartão';
    if (type.toLowerCase().contains('money') || type.toLowerCase().contains('dinheiro')) return 'Dinheiro';
    return type;
  }
}