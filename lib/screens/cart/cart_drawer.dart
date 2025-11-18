// lib/screens/cart/cart_drawer.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // ← NECESSÁRIO PARA A ANIMAÇÃO
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/models/cart_item.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_screen.dart';

Future<void> showCartDrawer(BuildContext context) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => const CartFullScreen(),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class CartFullScreen extends StatelessWidget {
  const CartFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Overlay escuro
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          // Painel principal – TODO BRANCO
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final items = controller.items;
              final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
              final isEmpty = items.isEmpty;

              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOutCubic),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: double.infinity,
                    color: Colors.white, // Fundo branco puro
                    child: Column(
                      children: [
                        // HEADER — só aparece quando tem itens
                        if (!isEmpty)
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                            color: Colors.white,
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Minha Caixa',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '$totalItems ${totalItems == 1 ? 'item' : 'itens'}',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close, size: 28),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[100],
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Botão X quando está vazio (fica no canto superior direito)
                        if (isEmpty)
                          SafeArea(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12, right: 12),
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close, size: 28),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey[100],
                                    shape: const CircleBorder(),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // CONTEÚDO
                        Expanded(
                          child: isEmpty
                              ? const _EmptyCart() // ← com seu Lottie lindo
                              : _CartWithItems(items: items, brl: brl),
                        ),

                        // FOOTER — só aparece quando tem itens
                        if (!isEmpty)
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(top: BorderSide(color: Colors.grey.shade200)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                              ],
                            ),
                            child: Column(
                              children: [
                                _summaryRow('Subtotal', brl.format(controller.subtotal)),
                                const SizedBox(height: 8),
                                _summaryRow('Taxa de Entrega', brl.format(controller.deliveryFee)),
                                const Divider(height: 32),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (context.mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                                        );
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFA4815),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 8,
                                    shadowColor: const Color(0xFFFA4815).withOpacity(0.4),
                                  ),
                                  child: Text(
                                    'Finalizar Pedido • ${brl.format(controller.total)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}

// ==================================================
// ESTADO VAZIO – COM SEU LOTTIE ANIMADO (só roda 1x)
// ==================================================== ==============================
class _EmptyCart extends StatefulWidget {
  const _EmptyCart();

  @override
  State<_EmptyCart> createState() => _EmptyCartState();
}

class _EmptyCartState extends State<_EmptyCart> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: Lottie.asset(
              'assets/lottie/empty_box.json',
              controller: _controller,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..forward(); // Toca uma única vez
              },
              repeat: false,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Sua caixa está vazia.',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Que tal adicionar alguns cortes suculentos?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA4815),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
            ),
            child: const Text('Ver Produtos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// ESTADO COM ITENS
// ==================================================
class _CartWithItems extends StatelessWidget {
  final List<CartItem> items;
  final NumberFormat brl;

  const _CartWithItems({required this.items, required this.brl});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 32),
      itemBuilder: (_, i) {
        final item = items[i];
        final product = item.product;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Image.network(
                  product.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.remove(product),
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        brl.format(item.totalPrice),
                        style: const TextStyle(
                          color: Color(0xFFFA4815),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => controller.decrement(product),
                              icon: const Icon(Icons.remove, size: 18),
                              padding: EdgeInsets.zero,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              onPressed: () => controller.increment(product),
                              icon: const Icon(Icons.add, size: 18),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}