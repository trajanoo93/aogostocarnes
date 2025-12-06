// lib/screens/product/product_details_page.dart - VERSÃO CORRETA DEFINITIVA

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/models/product_variation.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';
import 'package:ao_gosto_app/api/product_service.dart';

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

  Map<String, String> _selectedAttributes = {};
  List<ProductVariation> _variations = [];
  bool _loadingVariations = false;
  ProductVariation? _currentVariation;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    
    if (widget.product.hasVariations && widget.product.attributes != null) {
      for (final attr in widget.product.attributes!) {
        if (attr.options.isNotEmpty) {
          _selectedAttributes[attr.name] = attr.options.first;
        }
      }
    }

    if (widget.product.hasVariations) {
      _loadVariations();
    }
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
      
      print('\n✅ ${variations.length} variações carregadas para "${widget.product.name}"');
      for (final v in variations) {
        print('   ID ${v.id}: ${v.attributes} = R\$ ${v.price} ${v.inStock ? "✅" : "❌"}');
      }
      
    } catch (e) {
      print('❌ ERRO ao carregar variações: $e');
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
    print('🎯 Seleção inicial: $_selectedAttributes');
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

    print('🎯 Variação atual: ID ${_currentVariation?.id} = R\$ ${_currentVariation?.price}');
  }

  // ✨ LÓGICA CORRETA: 
  // - PRIMEIRO ATRIBUTO: Verifica se existe ALGUMA variação com essa opção
  // - OUTROS ATRIBUTOS: Verifica se existe variação COM os atributos já selecionados
  bool _isOptionAvailable(String attributeName, String option, int attributeIndex) {
    if (_variations.isEmpty) return true;

    // ✅ SE É O PRIMEIRO ATRIBUTO: Verifica apenas se existe ALGUMA variação com essa opção
    if (attributeIndex == 0) {
      return _variations.any((variation) {
        if (!variation.inStock) return false;
        if (variation.attributes.isEmpty) return true;
        
        final varAttrValue = variation.attributes[attributeName];
        if (varAttrValue == null || varAttrValue.isEmpty) return true;
        
        return varAttrValue == option;
      });
    }
    
    // ✅ SE É OUTRO ATRIBUTO: Verifica se existe variação compatível com os já selecionados
    return _variations.any((variation) {
      if (!variation.inStock) return false;
      if (variation.attributes.isEmpty) return true;
      
      // Verifica se esse atributo bate
      final varAttrValue = variation.attributes[attributeName];
      if (varAttrValue == null || varAttrValue.isEmpty) return true;
      if (varAttrValue != option) return false;
      
      // Verifica se OUTROS atributos selecionados são compatíveis
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

  String _cleanDescription(String html) {
    if (html.trim().isEmpty) return '';
    var s = html;
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n\n');
    s = s.replaceAll(RegExp(r'</div>\s*<div[^>]*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</div>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n- ');
    s = s.replaceAll(RegExp(r'</li>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll('&nbsp;', ' ');
    s = s.replaceAll('&#8211;', '-');
    s = s.replaceAll('&#8217;', "'");
    s = s.replaceAll('&#8220;', '"');
    s = s.replaceAll('&#8221;', '"');
    s = s.replaceAll('&amp;', '&');
    s = s.replaceAll('&quot;', '"');
    s = s.replaceAll('&lt;', '<');
    s = s.replaceAll('&gt;', '>');
    s = s.replaceAll(RegExp(r'&#\d+;'), '');
    s = s.replaceAll(RegExp(r'&[a-z]+;', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r' +'), ' ');
    s = s.replaceAll(RegExp(r'\t+'), '');
    s = s.replaceAll(RegExp(r' *\n *'), '\n');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    final lines = s.split('\n').map((line) => line.trim()).where((line) {
      if (line.isEmpty) return false;
      final upper = line.toUpperCase();
      return !upper.contains('IMAGEM') && !upper.contains('ILUSTRATIVA') && 
             !upper.contains('MERAMENTE') && !upper.startsWith('*') && !upper.contains('***');
    }).toList();
    
    return lines.join('\n').trim();
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: .2)),
        ],
      ),
    );
  }

  void _addToCart() async {
    for (var i = 0; i < _qty; i++) {
      CartController.instance.add(widget.product, selectedAttributes: widget.product.hasVariations ? _selectedAttributes : null);
    }
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
    final p = widget.product;
    final hasSale = p.regularPrice != null && p.regularPrice! > _currentPrice;

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
                title: _compactHeader ? Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)) : null,
                leading: Padding(padding: const EdgeInsets.only(left: 12), child: _HeaderBackButton(compact: _compactHeader)),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'prod-img-${p.id}',
                    child: Container(
                      color: const Color(0xFFF3F4F6),
                      child: Image.network(p.imageUrl, fit: BoxFit.cover, 
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.black26))),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(children: [
                        if (p.isBestseller) _badge('Mais vendido', const Color(0xFFF59E0B), Icons.workspace_premium_rounded),
                        if (p.isFrozen) _badge('Congelado', const Color(0xFF3B82F6), Icons.ac_unit_rounded),
                        if (p.isChilled) _badge('Resfriado', const Color(0xFF10B981), Icons.thermostat_rounded),
                        if (p.isSeasoned) _badge('Temperado', const Color(0xFFEF4444), Icons.restaurant_menu_rounded),
                      ]),
                      const SizedBox(height: 6),
                      Text(p.name, style: const TextStyle(fontSize: 26, height: 1.15, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        if (hasSale) ...[
                          Text(_brl.format(p.regularPrice), style: const TextStyle(fontSize: 16, color: Color(0xFF9CA3AF), 
                            decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                        ],
                        Text(_brl.format(_currentPrice), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        if (p.averageWeightGrams != null) _MetaPill(icon: Icons.scale_rounded, text: 'Aprox. ${p.averageWeightGrams!.toStringAsFixed(0)}g'),
                        if (p.pricePerKg != null) _MetaPill(icon: Icons.attach_money_rounded, text: '${_brl.format(p.pricePerKg)} / kg'),
                      ]),
                      const SizedBox(height: 24),
                      if (p.hasVariations && p.attributes != null) ...[
                        if (_loadingVariations)
                          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                        else
                          _buildVariationSelector(p),
                        const SizedBox(height: 24),
                      ],
                      const Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        final description = _cleanDescription(p.shortDescription ?? '');
                        if (description.isEmpty) {
                          return const Text('Sem descrição disponível.', style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)));
                        }
                        return Text(description, style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF374151)));
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(child: Align(alignment: Alignment.bottomCenter, child: _buildBottomBar())),
        ],
      ),
    );
  }

  Widget _buildVariationSelector(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: p.attributes!.asMap().entries.map((entry) {
        final index = entry.key;
        final attr = entry.value;
        final currentValue = _selectedAttributes[attr.name] ?? '';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(attr.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, 
                color: Color(0xFF18181B), letterSpacing: -0.3)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attr.options.map((option) {
                  final isSelected = currentValue == option;
                  final isAvailable = _isOptionAvailable(attr.name, option, index);
                  return _CleanVariationChip(
                    label: option,
                    isSelected: isSelected,
                    isAvailable: isAvailable,
                    onTap: isAvailable ? () {
                      setState(() {
                        _selectedAttributes[attr.name] = option;
                        _updateCurrentVariation();
                      });
                    } : null,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    final total = _currentPrice * _qty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.8)),
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))],
        ),
        child: Row(children: [
          _QtyStepper(qty: _qty, onChanged: (v) => setState(() => _qty = v)),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 56, child: ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, 
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(_brl.format(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
          ))),
        ]),
      ),
    );
  }
}

class _CleanVariationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onTap;
  const _CleanVariationChip({required this.label, required this.isSelected, required this.isAvailable, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFA4815) : isAvailable ? Colors.white : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFFFA4815) : isAvailable ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6), 
              width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFA4815).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, 
            color: isSelected ? Colors.white : isAvailable ? const Color(0xFF18181B) : const Color(0xFF9CA3AF),
            letterSpacing: -0.2, decoration: isAvailable ? null : TextDecoration.lineThrough)),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
      ]),
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
      height: 56, width: 148,
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(999)),
      child: Row(children: [
        _RoundIcon(icon: Icons.remove_rounded, enabled: qty > 1, onTap: qty > 1 ? () => onChanged(qty - 1) : null),
        Expanded(child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87))),
        _RoundIcon(icon: Icons.add_rounded, onTap: () => onChanged(qty + 1)),
      ]),
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
      width: 56, height: 56,
      child: InkResponse(onTap: enabled ? onTap : null, customBorder: const CircleBorder(), 
        child: Icon(icon, size: 22, color: enabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF))),
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
      child: InkWell(onTap: () => Navigator.of(context).maybePop(), 
        child: SizedBox(width: compact ? 40 : 44, height: compact ? 40 : 44, 
          child: Icon(Icons.arrow_back_rounded, color: compact ? Colors.black : Colors.white))),
    );
  }
}