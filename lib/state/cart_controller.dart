  // lib/state/cart_controller.dart

  import 'dart:convert';
  import 'package:flutter/foundation.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:ao_gosto_app/models/cart_item.dart';
  import 'package:ao_gosto_app/models/product.dart';

  class CartController extends ChangeNotifier {
    CartController._() {
      _loadPersistedFee();
    }

    static final CartController instance = CartController._();

    final List<CartItem> _items = [];
    List<CartItem> get items => List.unmodifiable(_items);

    double _deliveryFee = 15.0;
    double get deliveryFee => _deliveryFee;

    int get totalItems => _items.fold(0, (t, e) => t + e.quantity);
    double get subtotal => _items.fold(0.0, (t, e) => t + e.totalPrice);
    double get total => _items.isEmpty ? 0.0 : subtotal + deliveryFee;

    // ======================================================
    // ADICIONAR COM SUPORTE A VARIAÇÃO E ATRIBUTOS
    // ======================================================
    void add(
      Product product, {
      int quantity = 1,
      int? variationId,
      Map<String, String>? selectedAttributes,
    }) {
      final index = _items.indexWhere(
        (i) => i.product.id == product.id && i.variationId == variationId,
      );

      if (index >= 0) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity + quantity,
        );
      } else {
        _items.add(
          CartItem(
            product: product,
            quantity: quantity,
            variationId: variationId,
            selectedAttributes: selectedAttributes,
          ),
        );
      }

      notifyListeners();
    }

    // ======================================================
    // INCREMENTAR
    // ======================================================
    void increment(
      Product product, {
      int? variationId,
      Map<String, String>? selectedAttributes,
    }) {
      final index = _items.indexWhere(
        (i) => i.product.id == product.id && i.variationId == variationId,
      );

      if (index >= 0) {
        _items[index] =
            _items[index].copyWith(quantity: _items[index].quantity + 1);
        notifyListeners();
      }
    }

    // ======================================================
    // DECREMENTAR
    // ======================================================
    void decrement(
      Product product, {
      int? variationId,
      Map<String, String>? selectedAttributes,
    }) {
      final index = _items.indexWhere(
        (i) => i.product.id == product.id && i.variationId == variationId,
      );

      if (index >= 0) {
        final newQty = _items[index].quantity - 1;

        if (newQty <= 0) {
          _items.removeAt(index);
        } else {
          _items[index] = _items[index].copyWith(quantity: newQty);
        }

        notifyListeners();
      }
    }

    // ======================================================
    // REMOVER ITEM DO CARRINHO
    // ======================================================
    void remove(
      Product product, {
      int? variationId,
    }) {
      _items.removeWhere(
        (i) => i.product.id == product.id && i.variationId == variationId,
      );
      notifyListeners();
    }

    // ======================================================
    // ENTREGA
    // ======================================================
    void setDeliveryFee(double fee) {
      if (_deliveryFee != fee) {
        _deliveryFee = fee;
        notifyListeners();
      }
    }

    Future<void> _loadPersistedFee() async {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getDouble('delivery_fee');
      if (saved != null && saved > 0) {
        setDeliveryFee(saved);
      }
    }

    Future<void> updateDeliveryFee(String cep) async {
      try {
        final uri = Uri.parse(
          'https://aogosto.com.br/delivery/wp-json/custom/v1/shipping-cost?cep=$cep',
        );

        final resp =
            await http.get(uri).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          final options = data['shipping_options'] as List?;

          if (options?.isNotEmpty == true) {
            final costStr = options!.first['cost'].toString();
            final cost =
                double.tryParse(costStr.replaceAll(',', '.')) ?? 0.0;

            setDeliveryFee(cost);

            final sp = await SharedPreferences.getInstance();
            await sp.setDouble('delivery_fee', cost);
          }
        }
      } catch (_) {}
    }

    Future<void> loadDeliveryFee(Future<double> Function() loader) async {
      try {
        final fee = await loader();
        setDeliveryFee(fee);
      } catch (_) {}
    }
  }
