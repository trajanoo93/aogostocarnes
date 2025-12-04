// lib/widgets/variation_selector_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';

/// 🎨 MODAL SURPREENDENTE DE SELEÇÃO DE VARIAÇÕES
Future<void> showVariationSelector({
  required BuildContext context,
  required Product product,
}) async {
  // Se o produto não tem variações, adiciona direto
  if (!product.isVariable) {
    CartController.instance.add(product);
    await showCartDrawer(context);
    return;
  }

  // Se tem variações, mostra o modal
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _VariationSelectorModal(product: product),
  );
}

class _VariationSelectorModal extends StatefulWidget {
  final Product product;

  const _VariationSelectorModal({required this.product});

  @override
  State<_VariationSelectorModal> createState() =>
      _VariationSelectorModalState();
}

class _VariationSelectorModalState extends State<_VariationSelectorModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String> _selectedAttributes = {};

  @override
  void initState() {
    super.initState();

    // ✅ Pré-seleciona primeira opção de cada atributo
    if (widget.product.attributes != null) {
      for (final attr in widget.product.attributes!) {
        if (attr.options.isNotEmpty) {
          _selectedAttributes[attr.name] = attr.options.first;
        }
      }
    }

    // 🎬 Animações de entrada
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _addToCart() async {
    final navigator = Navigator.of(context);

    // Fecha o modal com animação
    await _animController.reverse();
    navigator.pop();

    // Adiciona ao carrinho
    CartController.instance.add(
      widget.product,
      selectedAttributes: _selectedAttributes,
    );

    // Abre o carrinho
    await showCartDrawer(context);
  }

  @override
  Widget build(BuildContext context) {
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animController,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════════════════════════════════
            //              HEADER COM IMAGEM
            // ═══════════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Imagem + Info
                  Row(
                    children: [
                      // Imagem
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.network(
                            widget.product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Nome + Preço
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF18181B),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              brl.format(widget.product.price),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFA4815),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════
            //           SELETORES DE VARIAÇÕES
            // ═══════════════════════════════════════════
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    const Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 20,
                          color: Color(0xFF71717A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Personalize seu pedido',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF71717A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Lista de atributos
                    if (widget.product.attributes != null)
                      ...widget.product.attributes!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final attr = entry.value;
                        final isLast =
                            index == widget.product.attributes!.length - 1;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 24,
                          ),
                          child: _AttributeSelector(
                            attribute: attr,
                            selectedValue: _selectedAttributes[attr.name],
                            onSelect: (value) {
                              setState(() {
                                _selectedAttributes[attr.name] = value;
                              });
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // ═══════════════════════════════════════════
            //              BOTÃO ADICIONAR
            // ═══════════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFA4815),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Adicionar à Caixinha',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
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
//              SELETOR DE ATRIBUTO INDIVIDUAL
// ═══════════════════════════════════════════════════════════
class _AttributeSelector extends StatelessWidget {
  final ProductAttribute attribute;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  const _AttributeSelector({
    required this.attribute,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label do atributo
        Text(
          attribute.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF18181B),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 12),

        // Grid de opções
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: attribute.options.map((option) {
            final isSelected = option == selectedValue;

            return _VariationChip(
              label: option,
              isSelected: isSelected,
              onTap: () => onSelect(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//              CHIP DE VARIAÇÃO ANIMADO
// ═══════════════════════════════════════════════════════════
class _VariationChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VariationChip> createState() => _VariationChipState();
}

class _VariationChipState extends State<_VariationChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFFA4815)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFFA4815)
                  : const Color(0xFFE5E7EB),
              width: widget.isSelected ? 2 : 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFA4815).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.isSelected
                  ? Colors.white
                  : const Color(0xFF18181B),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}