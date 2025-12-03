// lib/models/product.dart - ATUALIZADO COM VARIAÇÕES

class Product {
  final int id;
  final String name;
  final double price;
  final double? regularPrice;
  final String imageUrl;

  // Mantém compatibilidade: pode existir string de categoria em alguns usos
  final String? category;

  // Para filtros/"Todos os Cortes"
  final List<int> categoryIds;

  // Campos para detalhes e badges
  final String? shortDescription;
  final double? pricePerKg;          // ex.: 59.90
  final double? averageWeightGrams;  // ex.: 850
  final bool isFrozen;               // "Congelado"
  final bool isChilled;              // "Resfriado"
  final bool isSeasoned;             // "Temperado"
  final bool isBestseller;           // "Mais vendido"

  // ✨ NOVO: Suporte a variações
  final String type;                 // "simple" ou "variable"
  final List<ProductAttribute>? attributes;  // Atributos (ex: Sabor)
  final List<int>? variationIds;     // IDs das variações

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.regularPrice,
    required this.imageUrl,
    this.category,
    this.categoryIds = const [],
    this.shortDescription,
    this.pricePerKg,
    this.averageWeightGrams,
    this.isFrozen = false,
    this.isChilled = false,
    this.isSeasoned = false,
    this.isBestseller = false,
    this.type = 'simple',
    this.attributes,
    this.variationIds,
  });

  bool get isVariable => type == 'variable';
  bool get hasVariations => variationIds != null && variationIds!.isNotEmpty;

  factory Product.fromWoo(Map<String, dynamic> p) {
    final images = (p['images'] as List?) ?? const [];
    final img = images.isNotEmpty ? (images.first['src'] as String? ?? '') : '';
    final catsRaw = (p['categories'] as List?) ?? const [];
    final cats = catsRaw
        .map((c) {
          try {
            return c['id'] as int;
          } catch (_) {
            return null;
          }
        })
        .whereType<int>()
        .toList();

    final meta = (p['meta_data'] as List?) ?? const [];
    double? metaDouble(String key) {
      try {
        final m = meta.firstWhere((e) => e['key'] == key, orElse: () => null);
        final v = m == null ? null : m['value'];
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString().replaceAll(',', '.'));
      } catch (_) {
        return null;
      }
    }

    bool metaBool(String key) {
      try {
        final m = meta.firstWhere((e) => e['key'] == key, orElse: () => null);
        final v = m == null ? null : m['value'];
        if (v is bool) return v;
        if (v is String) {
          final s = v.toLowerCase();
          return s == 'yes' || s == '1' || s == 'true';
        }
      } catch (_) {}
      return false;
    }

    // ✨ PARSE ATRIBUTOS E VARIAÇÕES
    List<ProductAttribute>? attributes;
    List<int>? variationIds;
    
    if (p['type'] == 'variable') {
      // Atributos
      final attrsRaw = (p['attributes'] as List?) ?? [];
      attributes = attrsRaw
          .where((a) => a['variation'] == true)
          .map((a) => ProductAttribute(
                name: a['name'] ?? '',
                options: (a['options'] as List?)?.cast<String>() ?? [],
              ))
          .toList();
      
      // IDs das variações
      variationIds = (p['variations'] as List?)?.cast<int>() ?? [];
    }

    return Product(
      id: (p['id'] as num).toInt(),
      name: (p['name'] as String?) ?? '',
      price: double.tryParse(p['price']?.toString() ?? '') ?? 0.0,
      regularPrice: p['regular_price'] != null
          ? double.tryParse(p['regular_price'].toString())
          : null,
      imageUrl: img.isNotEmpty
          ? img
          : 'https://aogosto.com.br/delivery/wp-content/uploads/2023/12/Go-Express-fundo-400-x-200-px2-1.png',
      categoryIds: cats,
      shortDescription: p['short_description'] as String?,
      pricePerKg: metaDouble('_price_per_kg'),
      averageWeightGrams: metaDouble('_weight_grams'),
      isFrozen: metaBool('_is_frozen'),
      isChilled: metaBool('_is_chilled'),
      isSeasoned: metaBool('_is_seasoned'),
      isBestseller: metaBool('_is_bestseller'),
      type: p['type'] ?? 'simple',
      attributes: attributes,
      variationIds: variationIds,
    );
  }
}

// ✨ CLASSE DE ATRIBUTO (SIMPLES)
class ProductAttribute {
  final String name;
  final List<String> options;

  const ProductAttribute({
    required this.name,
    required this.options,
  });
}