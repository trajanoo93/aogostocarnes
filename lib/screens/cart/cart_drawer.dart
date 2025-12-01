// lib/screens/cart/cart_drawer.dart - VERSÃO ULTRA MODERNA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/models/cart_item.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/screens/checkout/checkout_screen.dart';
import 'package:ao_gosto_app/screens/product/product_details_page.dart';

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

          // Painel principal
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
                        // HEADER MODERNO
                        if (!isEmpty) _ModernHeader(totalItems: totalItems),

                        // Botão X quando vazio
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
                              ? const _EmptyCart()
                              : _CartWithItems(items: items, brl: brl),
                        ),

                        // FOOTER PREMIUM
                        if (!isEmpty) _PremiumFooter(brl: brl),
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
//              HEADER MODERNO COM LARANJA
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
                // Título: "Meus Cortes" (Cortes em laranja)
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
//              FOOTER PREMIUM SEM TAXA
// ═══════════════════════════════════════════════════════════
class _PremiumFooter extends StatelessWidget {
  final NumberFormat brl;
  
  const _PremiumFooter({required this.brl});
  
  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
            
            const SizedBox(height: 16),
            
            // Botão Clean e Elegante
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ CORREÇÃO: Salvar contexto e navigator ANTES do async
                  final navigator = Navigator.of(context);
                  
                  // Fecha o drawer
                  navigator.pop();
                  
                  // Navega para o checkout SEM delay
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
        style: TextStyle(color: Color(0xFFFA4815)), // 🔥 Cor laranja do botão
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
//              CARRINHO COM ITENS + UP-SELLING
// ═══════════════════════════════════════════════════════════
class _CartWithItems extends StatelessWidget {
  final List<CartItem> items;
  final NumberFormat brl;

  const _CartWithItems({required this.items, required this.brl});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        // Lista de itens
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final product = item.product;

          return Padding(
            padding: EdgeInsets.only(
              bottom: i < items.length - 1 ? 20 : 0,
            ),
            child: _CartItemCard(
              item: item,
              product: product,
              brl: brl,
              controller: controller,
            ),
          );
        }),
        
        // Up-selling (discreto)
        const SizedBox(height: 32),
        const _UpSellingSection(),
      ],
    );
  }
}

// === CARD DO ITEM ===
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final Product product;
  final NumberFormat brl;
  final CartController controller;
  
  const _CartItemCard({
    required this.item,
    required this.product,
    required this.brl,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                product.imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFF9CA3AF),
                  ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF18181B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.remove(product),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Preço
                    Text(
                      brl.format(item.totalPrice),
                      style: const TextStyle(
                        color: Color(0xFFFA4815),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    
                    // Contador
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => controller.decrement(product),
                            icon: const Icon(Icons.remove, size: 16),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => controller.increment(product),
                            icon: const Icon(Icons.add, size: 16),
                            padding: const EdgeInsets.all(8),
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
//            UP-SELLING DISCRETO (CATEGORIA 250)
// ═══════════════════════════════════════════════════════════
class _UpSellingSection extends StatefulWidget {
  const _UpSellingSection();
  
  @override
  State<_UpSellingSection> createState() => _UpSellingSectionState();
}

class _UpSellingSectionState extends State<_UpSellingSection> {
  List<Product> _products = [];
  bool _loading = true;
  bool _hidden = false; // ✅ Estado para ocultar
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    try {
      final service = ProductService();
      final products = await service.fetchProductsByCategory(250, perPage: 10);
      
      // Filtrar produtos que já estão no carrinho
      final cartController = CartController.instance;
      final cartProductIds = cartController.items.map((e) => e.product.id).toSet();
      final filtered = products.where((p) => !cartProductIds.contains(p.id)).toList();
      
      if (mounted) {
        setState(() {
          _products = filtered.take(10).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading || _hidden) {
      return const SizedBox.shrink();
    }
    
    if (_products.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32), // ✅ Espaço maior antes
        
        // Header com botão fechar
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                size: 16,
                color: Color(0xFFFA4815),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Não deixe de experimentar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
            ),
            // ✅ Botão fechar
            IconButton(
              onPressed: () => setState(() => _hidden = true),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF71717A),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Grid horizontal compacto
        SizedBox(
          height: 140, // ✅ Altura reduzida
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final product = _products[i];
              return _CompactUpSellingCard(product: product);
            },
          ),
        ),
        
        const SizedBox(height: 24), // ✅ Espaço antes do footer
      ],
    );
  }
}

// === CARD UP-SELLING COMPACTO ===
class _CompactUpSellingCard extends StatelessWidget {
  final Product product;
  
  const _CompactUpSellingCard({required this.product});
  
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
        width: 110, // ✅ Mais compacto
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem compacta
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: 70, // ✅ Altura fixa menor
                width: double.infinity,
                child: Image.network(
                  product.imageUrl ?? '',
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
            
            // Info compacta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nome
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Preço + Botão
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            brl.format(product.price),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFA4815),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Botão adicionar compacto
                        GestureDetector(
                          onTap: () {
                            controller.add(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Adicionado!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFA4815),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    // 🎬 Entry Animation (vibrante)
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

    // ♾️ Loop Animation (super leve)
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

    // ⏳ Start intro, depois deixa flutuando
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
        width: 180, // 🔥 menor e mais elegante
        height: 180,
      ),
    );
  }
}
