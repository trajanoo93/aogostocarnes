// lib/models/cart_item.dart

import 'package:ao_gosto_app/models/product.dart';

class CartItem {
  final Product product; // <- O app inteiro espera isso existir
  final int quantity;
  final int? variationId;
  final Map<String, String>? selectedAttributes;

  CartItem({
    required this.product,
    required this.quantity,
    this.variationId,
    this.selectedAttributes,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    int? variationId,
    Map<String, String>? selectedAttributes,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variationId: variationId ?? this.variationId,
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
    );
  }
}
