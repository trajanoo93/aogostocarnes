// lib/screens/checkout/widgets/summary_checkout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_controller.dart';

class SummaryCheckout extends StatefulWidget {
  const SummaryCheckout({super.key});

  @override
  State<SummaryCheckout> createState() => _SummaryCheckoutState();
}

class _SummaryCheckoutState extends State<SummaryCheckout> {
  bool _expanded = false;
  final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    final items = CartController.instance.items;

    return Container(
      decoration: _boxDeco(),
      child: Column(
        children: [
          // HEADER COLAPSÁVEL
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Ícone
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'itens'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Total
                  Text(
                    _currency.format(c.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Seta
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // CONTEÚDO EXPANDIDO
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // LISTA DE PRODUTOS
                  ...items.map((item) => _ProductItem(
                    item: item,
                    currency: _currency,
                  )),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // CUPOM
                  _CouponSection(currency: _currency),
                  
                  const SizedBox(height: 16),
                  
                  // TOTAIS
                  _TotalsSection(currency: _currency),
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

// ═══════════════════════════════════════════════════════════
//                    ITEM DO PRODUTO
// ═══════════════════════════════════════════════════════════
class _ProductItem extends StatelessWidget {
  final dynamic item; // Idealmente seria CartItem, mas dynamic funciona se o objeto tiver as props
  final NumberFormat currency;
  
  const _ProductItem({required this.item, required this.currency});
  
  @override
  Widget build(BuildContext context) {
    // ✅ CORREÇÃO: Usa unitPrice (inteligente) se disponível, senão fallback para product.price
    // Se 'item' for CartItem, ele tem o getter unitPrice e totalPrice
    final double priceToUse = (item.unitPrice is double) ? item.unitPrice : item.product.price;
    final double totalToUse = (item.totalPrice is double) ? item.totalPrice : (priceToUse * item.quantity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Imagem
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.product.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFFF4F4F5),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFF71717A),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Mostra variações se houver
                if (item.selectedAttributes != null && item.selectedAttributes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.selectedAttributes!.entries
                          .map((e) => "${e.key}: ${e.value}")
                          .join(" | "),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF71717A),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 2),
                Text(
                  'Qtd: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Preço
          Text(
            currency.format(totalToUse), // ✅ Agora usa o preço certo (totalPrice)
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════
//                    SEÇÃO DE CUPOM
// ═══════════════════════════════════════════════════════════
class _CouponSection extends StatefulWidget {
  final NumberFormat currency;
  
  const _CouponSection({required this.currency});
  
  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  bool _showInput = false;
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    // Cupom já aplicado
    if (c.appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.discount_rounded,
              color: Colors.green[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.appliedCoupon!.code,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.green[900],
                    ),
                  ),
                  Text(
                    'Desconto aplicado',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '- ${widget.currency.format(c.appliedCoupon!.discount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                c.removeCoupon();
                setState(() {});
              },
              icon: Icon(
                Icons.close_rounded,
                color: Colors.green[700],
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }
    
    // Input de cupom
    if (_showInput) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ex: BEMVINDO10',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF71717A),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: c.isApplyingCoupon
                      ? null
                      : () async {
                          await c.applyCoupon(_controller.text.trim());
                          setState(() => _showInput = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: c.isApplyingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Aplicar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          
          if (c.couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.couponError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    
    // Botão adicionar cupom
    return InkWell(
      onTap: () => setState(() => _showInput = true),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Adicionar cupom de desconto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//                    SEÇÃO DE TOTAIS
// ═══════════════════════════════════════════════════════════
class _TotalsSection extends StatelessWidget {
  final NumberFormat currency;
  
  const _TotalsSection({required this.currency});
  
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CheckoutController>();
    
    return Column(
      children: [
        _TotalRow(
          label: 'Subtotal',
          value: currency.format(c.subtotal),
        ),
        
        _TotalRow(
          label: 'Taxa de Entrega',
          value: currency.format(
            c.deliveryType == DeliveryType.delivery ? c.deliveryFee : 0.0,
          ),
        ),
        
        if (c.appliedCoupon != null)
          _TotalRow(
            label: 'Desconto',
            value: '- ${currency.format(c.appliedCoupon!.discount)}',
            valueColor: Colors.green[700],
          ),
        
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        
        _TotalRow(
          label: 'Total',
          value: currency.format(c.total),
          bold: true,
          large: true,
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool large;
  final Color? valueColor;
  
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.large = false,
    this.valueColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 15 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xFF71717A),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 17 : 15,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? const Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }
}

// === ESTILO ===
BoxDecoration _boxDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );