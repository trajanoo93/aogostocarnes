import 'package:flutter/foundation.dart';
import 'package:aogosto_carnes_flutter/models/cart_item.dart';
import 'package:aogosto_carnes_flutter/models/product.dart';

class CartController extends ChangeNotifier {
  CartController._();
  static final CartController instance = CartController._();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  double deliveryFee = 15.0;

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

  // ----- Preparando a taxa de entrega -----
  void setDeliveryFee(double fee) {
    deliveryFee = fee;
    notifyListeners();
  }

  Future<void> loadDeliveryFee(Future<double> Function() loader) async {
    try {
      final fee = await loader();
      setDeliveryFee(fee);
    } catch (_) {
      // mantém taxa atual em caso de erro
    }
  }

  bool _sameId(Product a, Product b) {
    try { return a.id == b.id; } catch (_) { return identical(a, b); }
  }
}
