// lib/widgets/variation_selector_modal.dart - VERSÃO CORRETA DEFINITIVA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/models/product_variation.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';
import 'package:ao_gosto_app/api/product_service.dart';

Future<void> showVariationSelector({
  required BuildContext context,
  required Product product,
}) async {
  if (!product.isVariable) {
    CartController.instance.add(product);
    await showCartDrawer(context);
    return;
  }

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
  State<_VariationSelectorModal> createState() => _VariationSelectorModalState();
}

class _VariationSelectorModalState extends State<_VariationSelectorModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String> _selectedAttributes = {};
  List<ProductVariation> _variations = [];
  bool _loadingVariations = false;
  ProductVariation? _currentVariation;

  @override
  void initState() {
    super.initState();

    if (widget.product.attributes != null) {
      for (final attr in widget.product.attributes!) {
        if (attr.options.isNotEmpty) {
          _selectedAttributes[attr.name] = attr.options.first;
        }
      }
    }

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
    _loadVariations();
  }

  Future<void> _loadVariations() async {
    setState(() => _loadingVariations = true);
    try {
      final service = ProductService();
      final variations = await service.fetchProductVariations(widget.product.id);
      setState(() {
        _variations = variations;
        _loadingVariations = false;
        _smartSelectFirstAvailable();
      });
    } catch (e) {
      print('❌ Erro ao carregar variações no modal: $e');
      setState(() => _loadingVariations = false);
    }
  }

  void _smartSelectFirstAvailable() {
    if (_variations.isEmpty) return;
    
    final firstAvailable = _variations.firstWhere((v) => v.inStock, orElse: () => _variations.first);
    
    if (firstAvailable.attributes.isNotEmpty) {
      _selectedAttributes.clear();
      _selectedAttributes.addAll(firstAvailable.attributes);
    }
    
    _updateCurrentVariation();
  }

  void _updateCurrentVariation() {
    if (_variations.isEmpty) {
      _currentVariation = null;
      return;
    }

    _currentVariation = _variations.firstWhere(
      (v) {
        for (final selected in _selectedAttributes.entries) {
          final varValue = v.attributes[selected.key];
          if (varValue != selected.value) return false;
        }
        return true;
      },
      orElse: () => _variations.first,
    );
  }

  // ✅ MESMA LÓGICA CORRETA
  bool _isOptionAvailable(String attributeName, String option, int attributeIndex) {
    if (_variations.isEmpty) return true;

    // PRIMEIRO ATRIBUTO: Verifica apenas se existe ALGUMA variação com essa opção
    if (attributeIndex == 0) {
      return _variations.any((variation) {
        if (!variation.inStock) return false;
        if (variation.attributes.isEmpty) return true;
        
        final varAttrValue = variation.attributes[attributeName];
        if (varAttrValue == null || varAttrValue.isEmpty) return true;
        
        return varAttrValue == option;
      });
    }
    
    // OUTROS ATRIBUTOS: Verifica se existe variação compatível com os já selecionados
    return _variations.any((variation) {
      if (!variation.inStock) return false;
      if (variation.attributes.isEmpty) return true;
      
      final varAttrValue = variation.attributes[attributeName];
      if (varAttrValue == null || varAttrValue.isEmpty) return true;
      if (varAttrValue != option) return false;
      
      for (final selectedAttr in _selectedAttributes.entries) {
        if (selectedAttr.key == attributeName) continue;
        
        final varValue = variation.attributes[selectedAttr.key];
        if (varValue != null && varValue.isNotEmpty && varValue != selectedAttr.value) {
          return false;
        }
      }
      
      return true;
    });
  }

  String get _headerMessage {
    final isKit = widget.product.categoryIds.contains(71);
    return isKit ? 'Personalize seu Kit' : 'Selecione uma opção';
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

 void _addToCart() async {
  final navigator = Navigator.of(context);
  await _animController.reverse();
  navigator.pop();
  
  // ✅ PASSA O variationId DA VARIAÇÃO SELECIONADA
  CartController.instance.add(
    widget.product,
    variationId: _currentVariation?.id,  // ✅ NOVO!
    selectedAttributes: _selectedAttributes,
  );
  
  await showCartDrawer(context);
}

  double get _currentPrice {
    if (_currentVariation != null) {
      return _currentVariation!.price;
    }
    return widget.product.price;
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
          child: SlideTransition(position: _slideAnimation, child: ScaleTransition(scale: _scaleAnimation, child: child)),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: Column(children: [
                Center(child: Container(width: 40, height: 4, 
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 80, height: 80, 
                    child: Image.network(widget.product.imageUrl, fit: BoxFit.cover, 
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], 
                        child: const Icon(Icons.image_not_supported_outlined, size: 32, color: Color(0xFF9CA3AF)))))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, 
                      color: Color(0xFF18181B), height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(brl.format(_currentPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, 
                      color: Color(0xFFFA4815))),
                  ])),
                ]),
              ]),
            ),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.restaurant_menu_rounded, size: 20, color: Color(0xFF71717A)),
                  const SizedBox(width: 8),
                  Text(_headerMessage, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, 
                    color: Color(0xFF71717A), letterSpacing: -0.2)),
                ]),
                const SizedBox(height: 20),
                if (_loadingVariations)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (widget.product.attributes != null)
                  ...widget.product.attributes!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final attr = entry.value;
                    final isLast = index == widget.product.attributes!.length - 1;
                    return Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 24), 
                      child: _AttributeSelector(
                        attribute: attr,
                        attributeIndex: index,
                        selectedValue: _selectedAttributes[attr.name],
                        onSelect: (value) {
                          setState(() {
                            _selectedAttributes[attr.name] = value;
                            _updateCurrentVariation();
                          });
                        },
                        isOptionAvailable: (option) => _isOptionAvailable(attr.name, option, index),
                      ));
                  }),
              ],
            ))),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
              child: SafeArea(top: false, child: SizedBox(width: double.infinity, height: 54, 
                child: ElevatedButton(onPressed: _addToCart, 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFA4815), foregroundColor: Colors.white, elevation: 0, 
                    shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.inventory_2_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Adicionar ${brl.format(_currentPrice)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ])))),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeSelector extends StatelessWidget {
  final ProductAttribute attribute;
  final int attributeIndex;
  final String? selectedValue;
  final ValueChanged<String> onSelect;
  final bool Function(String) isOptionAvailable;
  const _AttributeSelector({
    required this.attribute,
    required this.attributeIndex,
    required this.selectedValue,
    required this.onSelect,
    required this.isOptionAvailable
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(attribute.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF18181B), letterSpacing: -0.3)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: attribute.options.map((option) {
        final isSelected = option == selectedValue;
        final isAvailable = isOptionAvailable(option);
        return _VariationChip(label: option, isSelected: isSelected, isAvailable: isAvailable, 
          onTap: isAvailable ? () => onSelect(option) : null);
      }).toList()),
    ]);
  }
}

class _VariationChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onTap;
  const _VariationChip({required this.label, required this.isSelected, required this.isAvailable, this.onTap});

  @override
  State<_VariationChip> createState() => _VariationChipState();
}

class _VariationChipState extends State<_VariationChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isAvailable ? (_) => _controller.forward() : null,
      onTapUp: widget.isAvailable ? (_) { _controller.reverse(); widget.onTap?.call(); } : null,
      onTapCancel: widget.isAvailable ? () => _controller.reverse() : null,
      child: ScaleTransition(scale: _scaleAnimation, child: Opacity(opacity: widget.isAvailable ? 1.0 : 0.4, 
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFFFA4815) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isSelected ? const Color(0xFFFA4815) : widget.isAvailable ? 
              const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6), width: widget.isSelected ? 2 : 1.5),
            boxShadow: widget.isSelected ? [BoxShadow(color: const Color(0xFFFA4815).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : 
              [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, 
            color: widget.isSelected ? Colors.white : widget.isAvailable ? const Color(0xFF18181B) : const Color(0xFF9CA3AF),
            letterSpacing: -0.2, decoration: widget.isAvailable ? null : TextDecoration.lineThrough)),
        ))),
    );
  }
}