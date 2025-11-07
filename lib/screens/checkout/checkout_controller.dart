// lib/screens/checkout/checkout_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/api/shipping_service.dart';
import 'package:ao_gosto_app/api/onboarding_service.dart';
import 'package:ao_gosto_app/api/order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeliveryType { delivery, pickup }

class Address {
  final String id;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;

  const Address({
    required this.id,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });

  String get shortLine => '$street, $number';
}

class PickupLocation {
  final String key;
  final String name;
  final String address;

  const PickupLocation({required this.key, required this.name, required this.address});
}

class PaymentOption {
  final String id;
  final String name;
  final String subtitle;
  final bool disabled;
  const PaymentOption({
    required this.id,
    required this.name,
    required this.subtitle,
    this.disabled = false,
  });
}

class Coupon {
  final String code;
  final double discount;
  const Coupon({required this.code, required this.discount});
}

class CheckoutController extends ChangeNotifier {
  final ShippingService _shippingService;

  CheckoutController({ShippingService? shippingService})
      : _shippingService = shippingService ?? ShippingService();

  // -------- STATE PRINCIPAL --------
  int currentStep = 1; // 1: onde/quando | 2: pagamento
  DeliveryType deliveryType = DeliveryType.delivery;

  // Loading
  bool isLoading = true;

  // Perfil
  OnboardingProfile? profile;
  int? customerId;

  // Contato
  String userPhone = '';
  bool isEditingPhone = false;

  // Endereços e retirada
  List<Address> addresses = [];
  String? selectedAddressId;
  double deliveryFee = 0.0;

  // Retirada em loja
  final Map<String, PickupLocation> pickupLocations = const {
    'barreiro': PickupLocation(
      key: 'barreiro',
      name: 'Unidade Barreiro',
      address: 'Av. Sinfrônio Brochado, 612 - Barreiro, Belo Horizonte',
    ),
    'sagradaFamilia': PickupLocation(
      key: 'sagradaFamilia',
      name: 'Central Distribuição',
      address: 'Av. Silviano Brandão, 685 - Sagrada Família',
    ),
    'sion': PickupLocation(
      key: 'sion',
      name: 'Unidade Sion',
      address: 'R. Haití, 354 - Sion',
    ),
  };
  String selectedPickupKey = 'barreiro';

  // Observações
  bool showNotes = false;
  String orderNotes = '';

  // Cupom
  bool showCouponInput = false;
  bool isApplyingCoupon = false;
  String couponCode = '';
  String? couponError;
  Coupon? appliedCoupon;

  // Pagamento
  String paymentMethod = 'pix'; // pix, money, card-on-delivery, voucher
  bool needsChange = false;
  String changeForAmount = '';

  // Tela sucesso
  bool orderPlaced = false;
  String? orderId;

  // Intl
  final NumberFormat currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  // -------- CARRINHO --------
  double get subtotal {
    final items = CartController.instance.items;
    return items.fold<double>(0.0, (acc, it) => acc + it.product.price * it.quantity);
  }

  double get discount => appliedCoupon?.discount ?? 0.0;

  double get total {
    final fee = deliveryType == DeliveryType.delivery ? deliveryFee : 0.0;
    final t = (subtotal + fee - discount);
    return t < 0 ? 0.0 : t;
  }

  // -------- INÍCIO: carrega dados do onboarding (telefone + endereços) ------
  Future<void> bootstrapFromOnboarding() async {
    try {
      final sp = await SharedPreferences.getInstance();
      customerId = sp.getInt('customer_id');

      if (customerId != null) {
        profile = await OnboardingService().getProfile();
        userPhone = profile?.phone ?? userPhone;

        final addrs = <Address>[];
        if (profile?.address != null) {
          final a = profile!.address!;
          addrs.add(Address(
            id: 'addr1',
            street: a.street ?? 'Rua',
            number: a.number ?? '0',
            complement: a.complement,
            neighborhood: a.neighborhood ?? '',
            city: a.city ?? '',
            state: a.state ?? '',
            cep: a.cep ?? '',
          ));
        }
        addresses = addrs;
        selectedAddressId = addresses.isNotEmpty ? addresses.first.id : null;

        if (deliveryType == DeliveryType.delivery && addresses.isNotEmpty) {
          await refreshShippingFee();
        }
      }
    } catch (_) {
      // fallback silencioso
    } finally {
      isLoading = false;
    }
    notifyListeners();
  }

  // -------- AÇÕES / MUTATIONS --------
  void setDeliveryType(DeliveryType type) {
    deliveryType = type;
    notifyListeners();
  }

  void selectAddress(String id) {
    selectedAddressId = id;
    notifyListeners();
  }

  void toggleSummary() {
    // no momento, o resumo abre/fecha dentro da tela (a lógica ficará no widget)
    notifyListeners();
  }

  void startEditPhone() {
    isEditingPhone = true;
    notifyListeners();
  }

  void cancelEditPhone(String originalPhone) {
    isEditingPhone = false;
    userPhone = originalPhone;
    notifyListeners();
  }

  void savePhone() {
    isEditingPhone = false;
    notifyListeners();
    // aqui você poderia persistir no backend também
  }

  void setPhone(String raw) {
    userPhone = raw.replaceAll(RegExp(r'[^0-9]'), ''); // Remove máscara ao salvar
    notifyListeners();
  }

  void selectPickup(String key) {
    selectedPickupKey = key;
    notifyListeners();
  }

  void toggleNotes() {
    showNotes = true;
    notifyListeners();
  }

  void setOrderNotes(String notes) {
    orderNotes = notes;
    notifyListeners();
  }

  void showCoupon() {
    showCouponInput = true;
    notifyListeners();
  }

  Future<void> applyCoupon() async {
    isApplyingCoupon = true;
    couponError = null;
    notifyListeners();

    try {
      final coupon = await _fetchCoupon(couponCode.trim());
      if (coupon != null) {
        double discountValue = 0.0;
        final amount = double.parse(coupon['amount']);
        if (coupon['discount_type'] == 'percent') {
          discountValue = subtotal * (amount / 100);
        } else if (coupon['discount_type'] == 'fixed_cart') {
          discountValue = amount;
        } // Adicione outros tipos se necessário

        appliedCoupon = Coupon(code: couponCode.trim(), discount: discountValue);
        showCouponInput = false;
        couponCode = '';
      } else {
        couponError = 'Cupom inválido ou expirado.';
      }
    } catch (e) {
      couponError = 'Erro ao validar cupom.';
    }

    isApplyingCoupon = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _fetchCoupon(String code) async {
    final url = 'https://aogosto.com.br/delivery/wp-json/wc/v3/coupons?code=$code';
    final auth = base64Encode(utf8.encode('ck_5156e2360f442f2585c8c9a761ef084b710e811f:cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c'));
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Basic $auth',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      if (data.isNotEmpty) {
        final coupon = data.first as Map<String, dynamic>;
        // Verificar validade
        if (coupon['status'] == 'publish' && (coupon['date_expires'] == null || DateTime.parse(coupon['date_expires']).isAfter(DateTime.now()))) {
          return coupon;
        }
      }
    }
    return null;
  }

  void removeCoupon() {
    appliedCoupon = null;
    couponCode = '';
    couponError = null;
    notifyListeners();
  }

  void setPaymentMethod(String id) {
    paymentMethod = id;
    notifyListeners();
  }

  void toggleNeedsChange(bool v) {
    needsChange = v;
    if (!v) changeForAmount = '';
    notifyListeners();
  }

  void setChangeAmount(String v) {
    changeForAmount = v;
    notifyListeners();
  }

  Future<void> nextStep() async {
    if (currentStep == 1) {
      currentStep = 2;
      notifyListeners();
    } else {
      await placeOrder();
    }
  }

  void prevStep() {
    if (currentStep > 1) {
      currentStep--;
      notifyListeners();
    }
  }

  Future<void> refreshShippingFee() async {
    if (deliveryType != DeliveryType.delivery) {
      deliveryFee = 0.0;
      notifyListeners();
      return;
    }
    final addr = addresses.firstWhere(
      (a) => a.id == selectedAddressId,
      orElse: () => addresses.isNotEmpty ? addresses.first : const Address(
        id: 'none',
        street: '',
        number: '',
        neighborhood: '',
        city: '',
        state: '',
        cep: '',
      ),
    );
    if (addr.cep.isEmpty) {
      deliveryFee = 0.0;
      notifyListeners();
      return;
    }
    final v = await _shippingService.fetchDeliveryFee(addr.cep);
    deliveryFee = v;
    notifyListeners();
  }

  Future<void> placeOrder() async {
    if (profile == null) return;

    final selectedAddress = addresses.firstWhere(
      (a) => a.id == selectedAddressId,
      orElse: () => const Address(
        id: 'none',
        street: '',
        number: '',
        neighborhood: '',
        city: '',
        state: '',
        cep: '',
      ),
    );

    Map<String, dynamic> billing = {
      "first_name": profile!.name ?? '',
      "last_name": "",
      "company": "",
      "address_1": "${selectedAddress.street}, ${selectedAddress.number}",
      "address_2": selectedAddress.complement ?? '',
      "city": selectedAddress.city,
      "state": selectedAddress.state,
      "postcode": selectedAddress.cep,
      "country": "BR",
      "email": "", // Adicione se tiver email no profile
      "phone": userPhone,
    };

    Map<String, dynamic> shipping = Map.from(billing);

    if (deliveryType == DeliveryType.pickup) {
      final loc = pickupLocations[selectedPickupKey]!;
      shipping = {
        "first_name": profile!.name ?? '',
        "last_name": "",
        "company": loc.name,
        "address_1": loc.address,
        "address_2": "",
        "city": "Belo Horizonte",
        "state": "MG",
        "postcode": "",
        "country": "BR",
      };
    }

    final lineItems = CartController.instance.items.map((it) => {
          "product_id": it.product.id,
          "quantity": it.quantity,
          // Se houver variações: "variation_id": it.product.variationId,
        }).toList();

    final shippingLines = deliveryType == DeliveryType.delivery
        ? [
            {
              "method_id": "flat_rate", // Ajuste conforme configurado no Woo
              "method_title": "Entrega Padrão",
              "total": deliveryFee.toStringAsFixed(2),
            }
          ]
        : [];

    final couponLines = appliedCoupon != null
        ? [
            {"code": appliedCoupon!.code}
          ]
        : [];

    final metaData = <Map<String, dynamic>>[
      if (deliveryType == DeliveryType.pickup)
        {"key": "_pickup_location", "value": selectedPickupKey},
      if (needsChange && changeForAmount.isNotEmpty)
        {"key": "_change_for", "value": changeForAmount},
    ];

    String paymentTitle = '';
    switch (paymentMethod) {
      case 'pix':
        paymentTitle = 'PIX';
        break;
      case 'money':
        paymentTitle = 'Dinheiro na Entrega';
        break;
      case 'card-on-delivery':
        paymentTitle = 'Cartão na Entrega';
        break;
      case 'voucher':
        paymentTitle = 'Vale Alimentação';
        break;
    }

    final orderData = {
      "customer_id": customerId ?? 0,
      "payment_method": paymentMethod,
      "payment_method_title": paymentTitle,
      "set_paid": false, // Para PIX, ajuste se o plugin confirma via webhook
      "billing": billing,
      "shipping": shipping,
      "line_items": lineItems,
      "shipping_lines": shippingLines,
      "coupon_lines": couponLines,
      "customer_note": orderNotes,
      "meta_data": metaData,
    };

    try {
      final order = await OrderService().createOrder(orderData);
      orderId = order['id'].toString();
      CartController.instance.clear();
      orderPlaced = true;
    } catch (e) {
      // TODO: Mostrar erro ao usuário (ex.: Snackbar)
      if (kDebugMode) {
        print('Erro ao criar pedido: $e');
      }
    }
    notifyListeners();
  }

  // -------- MÉTODOS ADICIONAIS --------
  String formatPhone(String rawPhone) {
    if (rawPhone.length == 11 && RegExp(r'^\d{11}$').hasMatch(rawPhone)) {
      return '(${rawPhone.substring(0, 2)}) ${rawPhone.substring(2, 7)}-${rawPhone.substring(7)}';
    }
    return rawPhone;
  }

  Future<void> addOrUpdateAddress(Address address) async {
    // Simulação de chamada ao backend (substitua pelo endpoint real)
    final newAddress = Address(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporário, substitua por ID do backend
      street: address.street,
      number: address.number,
      complement: address.complement,
      neighborhood: address.neighborhood,
      city: address.city,
      state: address.state,
      cep: address.cep,
    );
    addresses.add(newAddress);
    selectedAddressId = newAddress.id;
    await refreshShippingFee();
    notifyListeners();
  }

  void editAddress(String id) {
    // Lógica para abrir um diálogo de edição (implementada no widget)
    notifyListeners();
  }
}