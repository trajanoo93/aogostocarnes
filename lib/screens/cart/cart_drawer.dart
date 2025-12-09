// lib/screens/cart/cart_drawer.dart - VERSÃO FINAL COM KITS E BOTÕES VERTICAIS

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/models/cart_item.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_screen.dart';
import 'package:ao_gosto_app/screens/product/product_details_page.dart';

// ═══════════════════════════════════════════════════════════
//              MAPA DE KITS E SEUS ITENS
// ═══════════════════════════════════════════════════════════
class KitItemsMap {
  static const Map<int, List<int>> kitItems = {
    89944: [343, 341, 1822], // KIT DELIVERY | PREÇO BAIXO
    438: [1822, 1928], // Kit 5 pessoas PREMIUM
    449: [331, 344, 345, 335, 343], // Kit Uruguay | 7 a 10 Pessoas
    446: [329, 335, 344, 345, 343], // Kit Churrasco 10 Pessoas
    12615: [341, 335, 345, 344], // Kit 10 Pessoas Steakhouse
    447: [331, 336, 335, 340, 345, 344], // Kit Churrasco 15 Pessoas
    12613: [331, 345, 344, 341, 336, 335], // Kit 20 Pessoas SteakHouse
    12610: [334, 336, 331, 335, 341, 345, 344, 339, 343], // Kit Uruguay | 20 Pessoas
    448: [329, 331, 336, 335, 341, 344, 345], // Kit Churrasco 20 Pessoas
  };

  // Retorna IDs dos produtos que devem ser ocultados baseado nos kits no carrinho
  static Set<int> getItemsToHideFromKits(List<CartItem> cartItems) {
    final Set<int> itemsToHide = {};
    
    for (final cartItem in cartItems) {
      final productId = cartItem.product.id;
      
      // Se o produto no carrinho é um kit, pega seus itens
      if (kitItems.containsKey(productId)) {
        itemsToHide.addAll(kitItems[productId]!);
      }
    }
    
    return itemsToHide;
  }
}

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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final items = controller.items;
              final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
              final isEmpty = items.isEmpty;

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: ModalRoute.of(context)!.animation!,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: double.infinity,
                    color: Colors.white,
                    child: Column(
                      children: [
                        if (!isEmpty) _ModernHeader(totalItems: totalItems),

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

                        Expanded(
                          child: isEmpty
                              ? const _EmptyCart()
                              : _CartWithItems(items: items, brl: brl),
                        ),

                        if (!isEmpty) _PremiumFooterWithUpselling(brl: brl),
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
}

// ═══════════════════════════════════════════════════════════
//              HEADER MODERNO
// ═══════════════════════════════════════════════════════════
class _ModernHeader extends StatelessWidget {
  final int totalItems;
  
  const _ModernHeader({required this.totalItems});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Meus ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF18181B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Cortes',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFA4815),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalItems ${totalItems == 1 ? 'item' : 'itens'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF71717A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF4F4F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//         FOOTER COM BOTÕES VERTICAIS E UP-SELLING
// ═══════════════════════════════════════════════════════════
class _PremiumFooterWithUpselling extends StatelessWidget {
  final NumberFormat brl;
  
  const _PremiumFooterWithUpselling({required this.brl});
  
  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✨ UP-SELLING COM LÓGICA DE KITS
            const _CompactUpsellingRow(),
            
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade100,
            ),
            
            // Subtotal + Botões VERTICAIS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF71717A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        brl.format(controller.subtotal),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // ✨ BOTÃO CONTINUAR (OUTLINE - ACIMA)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF18181B),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continuar Comprando',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // ✨ BOTÃO FINALIZAR (PREENCHIDO - ABAIXO)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFA4815),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Finalizar Pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//      UP-SELLING COM LÓGICA DE OCULTAR ITENS DE KITS
// ═══════════════════════════════════════════════════════════
class _CompactUpsellingRow extends StatefulWidget {
  const _CompactUpsellingRow();

  @override
  State<_CompactUpsellingRow> createState() => _CompactUpsellingRowState();
}

class _CompactUpsellingRowState extends State<_CompactUpsellingRow> {
  late final CartController _cartController;
  List<Product> _allSuggestions = [];
  List<Product> _visibleSuggestions = [];
  bool _loading = true;

  static final Map<int, Product> _upsellCache = {};

  static const List<int> _bestsellerIds = [
    1822, 376, 373, 345, 346, 342, 339, 337, 335, 331, 329,
  ];

  @override
  void initState() {
    super.initState();
    _cartController = CartController.instance;
    _loadBestsellers();
    _cartController.addListener(_updateVisibleProducts);
  }

  @override
  void dispose() {
    _cartController.removeListener(_updateVisibleProducts);
    super.dispose();
  }

  Future<void> _loadBestsellers() async {
    final cached = _bestsellerIds
        .where((id) => _upsellCache.containsKey(id))
        .map((id) => _upsellCache[id]!)
        .toList();

    if (cached.length == _bestsellerIds.length) {
      setState(() {
        _allSuggestions = cached;
        _loading = false;
      });
      _updateVisibleProducts();
      return;
    }

    final missingIds = _bestsellerIds.where((id) => !_upsellCache.containsKey(id)).toList();
    final idsParam = missingIds.join(',');

    if (missingIds.isEmpty) return;

    final url =
        'https://aogosto.com.br/delivery/wp-json/wc/v3/products?include=$idsParam&per_page=50&status=publish&consumer_key=ck_5156e2360f442f2585c8c9a761ef084b710e811f&consumer_secret=cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c';

    try {
      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        final List<Product> loaded = [];

        for (final item in data) {
          final product = Product.fromWoo(item as Map<String, dynamic>);
          _upsellCache[product.id] = product;
          loaded.add(product);
        }

        final allLoaded = _bestsellerIds.map((id) => _upsellCache[id]!).toList();

        if (mounted) {
          setState(() {
            _allSuggestions = allLoaded;
            _loading = false;
          });
          _updateVisibleProducts();
        }
      }
    } catch (e) {
      print('Erro upsell: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateVisibleProducts() {
    if (!mounted) return;

    // 1. IDs dos produtos que estão diretamente no carrinho
    final cartProductIds = _cartController.items.map((e) => e.product.id).toSet();
    
    // 2. IDs dos produtos que estão DENTRO dos kits do carrinho
    final kitItemsToHide = KitItemsMap.getItemsToHideFromKits(_cartController.items);
    
    // 3. Combina ambos os conjuntos
    final allIdsToHide = {...cartProductIds, ...kitItemsToHide};
    
    // 4. Filtra produtos do upsell
    final filtered = _allSuggestions.where((p) => !allIdsToHide.contains(p.id)).toList();

    setState(() {
      _visibleSuggestions = filtered;
    });
    
    print('🔍 Up-sell: ${_visibleSuggestions.length} produtos visíveis');
    print('❌ Ocultados: $allIdsToHide');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _visibleSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Não deixe de experimentar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF18181B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _visibleSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _MiniUpsellingCard(product: _visibleSuggestions[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//            CARD MINI UP-SELLING
// ═══════════════════════════════════════════════════════════
class _MiniUpsellingCard extends StatelessWidget {
  final Product product;
  
  const _MiniUpsellingCard({required this.product});
  
  @override
  Widget build(BuildContext context) {
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final controller = CartController.instance;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 70,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 24,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          brl.format(product.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFA4815),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.add(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Adicionado!'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                bottom: 80,
                                left: 20,
                                right: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFA4815),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//              CARRINHO VAZIO
// ═══════════════════════════════════════════════════════════
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
            width: 180,
            height: 180,
            child: const _AnimatedEmptyBox(),
          ),
          const SizedBox(height: 32),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF18181B),
              ),
              children: const [
                TextSpan(text: 'Sua '),
                TextSpan(
                  text: 'caixa',
                  style: TextStyle(color: Color(0xFFFA4815)),
                ),
                TextSpan(text: ' está vazia 😅'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Que tal adicionar alguns cortes suculentos?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF71717A),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA4815),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ver Produtos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//              CARRINHO COM ITENS
// ═══════════════════════════════════════════════════════════
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = items[i];
        final product = item.product;

        return _CompactCartItemCard(
          item: item,
          product: product,
          brl: brl,
          controller: controller,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//            CARD DO ITEM
// ═══════════════════════════════════════════════════════════
class _CompactCartItemCard extends StatelessWidget {
  final CartItem item;
  final Product product;
  final NumberFormat brl;
  final CartController controller;

  const _CompactCartItemCard({
    required this.item,
    required this.product,
    required this.brl,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF18181B),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    IconButton(
                      onPressed: () => controller.remove(
                        product,
                        variationId: item.variationId,
                      ),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                if (item.selectedAttributes != null &&
                    item.selectedAttributes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 6),
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: item.selectedAttributes!.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                              letterSpacing: -0.1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      brl.format(item.totalPrice),
                      style: const TextStyle(
                        color: Color(0xFFFA4815),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),

                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => controller.decrement(
                              product,
                              variationId: item.variationId,
                            ),
                            icon: const Icon(Icons.remove, size: 14),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () => controller.increment(
                              product,
                              variationId: item.variationId,
                            ),
                            icon: const Icon(Icons.add, size: 14),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//              ANIMATED EMPTY BOX
// ═══════════════════════════════════════════════════════════
class _AnimatedEmptyBox extends StatefulWidget {
  const _AnimatedEmptyBox();

  @override
  State<_AnimatedEmptyBox> createState() => _AnimatedEmptyBoxState();
}

class _AnimatedEmptyBoxState extends State<_AnimatedEmptyBox>
    with TickerProviderStateMixin {

  late AnimationController _introController;
  late AnimationController _loopController;

  late Animation<double> _introScale;
  late Animation<double> _introOpacity;
  late Animation<double> _introOffset;

  late Animation<double> _loopScale;
  late Animation<double> _loopOffset;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _introScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.elasticOut,
      ),
    );

    _introOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOut,
      ),
    );

    _introOffset = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _loopScale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _loopController,
        curve: Curves.easeInOut,
      ),
    );

    _loopOffset = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
        parent: _loopController,
        curve: Curves.easeInOut,
      ),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _loopController]),
      builder: (_, child) {
        final scale = _introController.isCompleted
            ? _loopScale.value
            : _introScale.value;

        final offsetY = _introController.isCompleted
            ? _loopOffset.value
            : _introOffset.value;

        final opacity = _introOpacity.value;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/images/caixinhaLaranja.png',
        width: 180,
        height: 180,
      ),
    );
  }
}