import 'package:ao_gosto_app/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final int? variationId;
  final Map<String, String>? selectedAttributes;
  final double? priceOverride; // ✅ NOVO: Para forçar o preço da variação

  const CartItem({
    required this.product,
    required this.quantity,
    this.variationId,
    this.selectedAttributes,
    this.priceOverride,
  });

  // Retorna o preço correto (Variação ou Pai)
  double get unitPrice => priceOverride ?? product.price;

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    double? priceOverride,
  }) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      variationId: variationId,
      selectedAttributes: selectedAttributes,
      priceOverride: priceOverride ?? this.priceOverride,
    );
  }
}