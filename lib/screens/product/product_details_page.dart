import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aogosto_carnes_flutter/models/product.dart';
import 'package:aogosto_carnes_flutter/utils/app_colors.dart';
import 'package:aogosto_carnes_flutter/state/cart_controller.dart';
import 'package:aogosto_carnes_flutter/screens/cart/cart_drawer.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final _brl = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final _scroll = ScrollController();
  bool _compactHeader = false;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scroll.offset > 40;
    if (scrolled != _compactHeader) {
      setState(() => _compactHeader = scrolled);
    }
  }

  String _htmlToPlainText(String html) {
    var s = html;
    s = s.replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll('&nbsp;', ' ').trim();
    return s;
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart() async {
    for (var i = 0; i < _qty; i++) {
      CartController.instance.add(widget.product);
    }
    await showCartDrawer(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasSale = p.regularPrice != null && p.regularPrice! > p.price;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: _compactHeader ? Colors.white : Colors.transparent,
                elevation: _compactHeader ? .5 : 0,
                pinned: true,
                expandedHeight: 340,
                centerTitle: false,
                title: _compactHeader
                    ? Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _HeaderBackButton(compact: _compactHeader),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'prod-img-${p.id}',
                    child: Container(
                      color: const Color(0xFFF3F4F6),
                      child: Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.black26),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ----- Conteúdo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // espaço pro bottom bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        children: [
                          if (p.isBestseller)
                            _badge('Mais vendido', const Color(0xFFF59E0B), Icons.workspace_premium_rounded),
                          if (p.isFrozen)
                            _badge('Congelado', const Color(0xFF3B82F6), Icons.ac_unit_rounded),
                          if (p.isChilled)
                            _badge('Resfriado', const Color(0xFF10B981), Icons.thermostat_rounded),
                          if (p.isSeasoned)
                            _badge('Temperado', const Color(0xFFEF4444), Icons.restaurant_menu_rounded),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Título
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Preços
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasSale) ...[
                            Text(
                              _brl.format(p.regularPrice),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF9CA3AF),
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            _brl.format(p.price),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // meta curta
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (p.averageWeightGrams != null)
                            _MetaPill(
                              icon: Icons.scale_rounded,
                              text: 'Aprox. ${p.averageWeightGrams!.toStringAsFixed(0)}g',
                            ),
                          if (p.pricePerKg != null)
                            _MetaPill(
                              icon: Icons.attach_money_rounded,
                              text: '${_brl.format(p.pricePerKg)} / kg',
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Descrição',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if ((p.shortDescription ?? '').trim().isNotEmpty) ...[
                        Text(
                          _htmlToPlainText(p.shortDescription!),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ] else
                        const Text(
                          'Sem descrição disponível.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ----- Bottom bar
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = widget.product.price * _qty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            _QtyStepper(
              qty: _qty,
              onChanged: (v) => setState(() => _qty = v),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adicionar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _brl.format(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
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

// ======= widgets auxiliares =======

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;

  const _QtyStepper({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 148,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _RoundIcon(
            icon: Icons.remove_rounded,
            enabled: qty > 1,
            onTap: qty > 1 ? () => onChanged(qty - 1) : null,
          ),
          Expanded(
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          _RoundIcon(
            icon: Icons.add_rounded,
            onTap: () => onChanged(qty + 1),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _RoundIcon({required this.icon, this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final bool compact;
  const _HeaderBackButton({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: compact ? Colors.white : Colors.black.withOpacity(.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          child: Icon(
            Icons.arrow_back_rounded,
            color: compact ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
