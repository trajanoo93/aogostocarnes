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

  void add(Product product, {int quantity = 1}) {
    final i = _items.indexWhere((e) => _sameId(e.product, product));
    if (i >= 0) {
      _items[i].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void increment(Product product) {
    final i = _items.indexWhere((e) => _sameId(e.product, product));
    if (i >= 0) {
      _items[i].quantity += 1;
      notifyListeners();
    }
  }

  void decrement(Product product) {
    final i = _items.indexWhere((e) => _sameId(e.product, product));
    if (i >= 0) {
      final newQty = _items[i].quantity - 1;
      if (newQty <= 0) {
        _items.removeAt(i);
      } else {
        _items[i].quantity = newQty;
      }
      notifyListeners();
    }
  }

  void remove(Product product) {
    _items.removeWhere((e) => _sameId(e.product, product));
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // ----- Taxa de entrega -----
  void setDeliveryFee(double fee) {
    if (_deliveryFee != fee) {
      _deliveryFee = fee;
      notifyListeners();
    }
  }

  /// Carrega a taxa salva no SharedPreferences
  Future<void> _loadPersistedFee() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getDouble('delivery_fee');
    if (saved != null && saved > 0) {
      setDeliveryFee(saved);
    }
  }

  /// Atualiza a taxa com base no CEP (chama API)
  Future<void> updateDeliveryFee(String cep) async {
    try {
      final uri = Uri.parse('https://aogosto.com.br/delivery/wp-json/custom/v1/shipping-cost?cep=$cep');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final options = data['shipping_options'] as List?;
        if (options?.isNotEmpty == true) {
          final costStr = options!.first['cost'].toString();
          final cost = double.tryParse(costStr.replaceAll(',', '.')) ?? 0.0;
          setDeliveryFee(cost);

          // Persiste o novo valor
          final sp = await SharedPreferences.getInstance();
          await sp.setDouble('delivery_fee', cost);
        }
      }
    } catch (_) {
      // Mantém o valor anterior em caso de erro
    }
  }

  // Compatibilidade com seu método antigo (opcional)
  Future<void> loadDeliveryFee(Future<double> Function() loader) async {
    try {
      final fee = await loader();
      setDeliveryFee(fee);
    } catch (_) {
      // mantém taxa atual
    }
  }

  bool _sameId(Product a, Product b) {
    try {
      return a.id == b.id;
    } catch (_) {
      return identical(a, b);
    }
  }
}