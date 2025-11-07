import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/models/cart_item.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_screen.dart';

Future<void> showCartDrawer(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final panelWidth = math.min(480.0, width * 0.9);

  return showGeneralDialog(
    context: context,
    barrierLabel: 'Carrinho',
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.7),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.centerRight,
      child: SizedBox(width: panelWidth, child: const _CartPanel()),
    ),
    transitionBuilder: (_, animation, __, child) {
      final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: slide, child: FadeTransition(opacity: animation, child: child));
    },
  );
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 24,
      shadowColor: Colors.black.withOpacity(0.2),
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
      child: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Text('Meu Carrinho', style: theme.textTheme.displayLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return controller.items.isEmpty
                      ? const EmptyCartWidget()
                      : _CartItemsList(items: controller.items, brl: brl);
                },
              ),
            ),

            // FOOTER
            const _CartSummaryFooter(),
          ],
        ),
      ),
    );
  }
}

class _CartItemsList extends StatelessWidget {
  final List<CartItem> items;
  final NumberFormat brl;
  const _CartItemsList({required this.items, required this.brl});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => CartItemWidget(item: items[i], brl: brl),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final NumberFormat brl;
  const CartItemWidget({required this.item, required this.brl});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final p = item.product;
    final theme = Theme.of(context);

    String? imageUrl;
    try {
      final url = (p as dynamic).imageUrl as String?;
      imageUrl = url?.isNotEmpty == true ? url : null;
    } catch (_) {}

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red[600],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => controller.remove(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Imagem
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 16),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(brl.format(item.totalPrice), style: theme.textTheme.headlineMedium),
                ],
              ),
            ),

            // Quantidade
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qtyBtn(Icons.remove, () => controller.decrement(p)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.quantity}', style: theme.textTheme.bodyLarge),
                  ),
                  _qtyBtn(Icons.add, () => controller.increment(p)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.black54),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Widget _placeholder() => Container(color: const Color(0xFFE5E7EB), child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26));
}

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Seu carrinho está vazio.', style: theme.textTheme.displayLarge!.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              'Adicione seus cortes favoritos para montar um churrasco inesquecível!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Continuar comprando', style: theme.textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummaryFooter extends StatelessWidget {
  const _CartSummaryFooter();

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.items.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Column(
            children: [
              _row('Subtotal', brl.format(controller.subtotal), theme),
              const SizedBox(height: 8),
              _row('Taxa de Entrega', brl.format(controller.deliveryFee), theme),
              const Divider(height: 32),
              _row('Total', brl.format(controller.total), theme, isTotal: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).maybePop();
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (context.mounted) {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const CheckoutScreen(),
                          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: Text('Finalizar Compra', style: theme.textTheme.headlineMedium!.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, ThemeData theme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.headlineSmall
              : theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}