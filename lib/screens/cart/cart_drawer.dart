import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:aogosto_carnes_flutter/state/cart_controller.dart';
import 'package:aogosto_carnes_flutter/utils/app_colors.dart';
import 'package:aogosto_carnes_flutter/models/cart_item.dart';
import 'package:aogosto_carnes_flutter/models/product.dart';
import 'package:aogosto_carnes_flutter/screens/checkout/checkout_screen.dart';

/// Chame `showCartDrawer(context)` para abrir o carrinho.
Future<void> showCartDrawer(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final panelW = math.min(420.0, width * 0.94);

  return showGeneralDialog(
    context: context,
    barrierLabel: 'Carrinho',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    pageBuilder: (_, __, ___) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: panelW,
          child: const _CartPanel(),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Material(
      color: Colors.white,
      elevation: 12,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final items = controller.items;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFF1F2), Colors.white],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      const Text('Meu Carrinho',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon:
                            const Icon(Icons.close, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: items.isEmpty
                      ? _EmptyCart(
                          onClose: () => Navigator.of(context).maybePop())
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemBuilder: (_, i) =>
                              _CartItemTile(items[i], brl),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: items.length,
                        ),
                ),

                // Footer
                if (items.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        _row('Subtotal', brl.format(controller.subtotal)),
                        const SizedBox(height: 6),
                        _row('Taxa de Entrega',
                            brl.format(controller.deliveryFee)),
                        const Divider(height: 20),
                        _row('Total', brl.format(controller.total),
                            isEmphasis: true),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                            ),
                            onPressed: () async {
                              // Fecha o drawer
                              Navigator.of(context).maybePop();

                              // Pequeno delay para a transição
                              await Future.delayed(
                                  const Duration(milliseconds: 250));

                              // Abre a tela de checkout
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CheckoutScreen()),
                              );
                            },
                            icon: const Icon(
                                Icons.arrow_forward_rounded),
                            label: const Text('Finalizar Compra',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(String l, String r, {bool isEmphasis = false}) {
    final styleL = TextStyle(
      color: Colors.grey[700],
      fontSize: isEmphasis ? 16 : 14,
      fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
    );
    final styleR = TextStyle(
      color: isEmphasis ? AppColors.primary : Colors.grey[800],
      fontSize: isEmphasis ? 18 : 14,
      fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(l, style: styleL), Text(r, style: styleR)],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onClose;
  const _EmptyCart({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 64, color: Color(0xFFFFE4E6)),
            const SizedBox(height: 12),
            const Text('Seu carrinho está vazio',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Adicione cortes premium para montar o melhor churrasco!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continuar comprando'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final NumberFormat brl;
  const _CartItemTile(this.item, this.brl);

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final p = item.product;

    String? imageUrl;
    try {
      final url = (p as dynamic).imageUrl as String?;
      imageUrl = (url != null && url.isNotEmpty) ? url : null;
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style:
                  const TextStyle(color: Colors.black87),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    brl.format(item.totalPrice),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Diminuir',
                  onPressed: () => controller.decrement(p),
                  icon: const Icon(Icons.remove,
                      size: 18, color: Colors.black54),
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                  padding: EdgeInsets.zero,
                ),
                Text('${item.quantity}',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  tooltip: 'Aumentar',
                  onPressed: () => controller.increment(p),
                  icon: const Icon(Icons.add,
                      size: 18, color: Colors.black54),
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Remover',
            onPressed: () => controller.remove(p),
            icon: const Icon(Icons.close,
                size: 18, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.image_not_supported_outlined,
            color: Colors.black26),
      );
}
