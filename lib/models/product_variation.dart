
// lib/models/product_variation.dart
class ProductVariation {
  final int id;
  final double price;
  final double? regularPrice;
  final String? imageUrl;
  final bool inStock;
  final Map<String, String> attributes; // {"Sabor": "Carne", "Tamanho": "500g"}

  const ProductVariation({
    required this.id,
    required this.price,
    this.regularPrice,
    this.imageUrl,
    required this.inStock,
    required this.attributes,
  });

  factory ProductVariation.fromWoo(Map<String, dynamic> json) {
    final images = (json['image'] as Map<String, dynamic>?);
    final attributesRaw = (json['attributes'] as List?) ?? [];
    
    // Mapeia atributos da variação
    final Map<String, String> attrs = {};
    for (final attr in attributesRaw) {
      final name = attr['name'] as String?;
      final option = attr['option'] as String?;
      if (name != null && option != null) {
        attrs[name] = option;
      }
    }

    return ProductVariation(
      id: (json['id'] as num).toInt(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      regularPrice: json['regular_price'] != null
          ? double.tryParse(json['regular_price'].toString())
          : null,
      imageUrl: images?['src'] as String?,
      inStock: (json['stock_status'] as String?) == 'instock',
      attributes: attrs,
    );
  }

  @override
  String toString() =>
      'ProductVariation(id: $id, price: $price, inStock: $inStock, attributes: $attributes)';
}
