// lib/screens/checkout/checkout_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/models/order_models.dart';
import 'package:ao_gosto_app/api/shipping_service.dart';
import 'package:ao_gosto_app/api/firestore_service.dart';
import 'package:ao_gosto_app/api/onboarding_service.dart';
import 'package:ao_gosto_app/api/order_service.dart';


/// Modelo de slot de horário
class TimeSlot {
  final String id;
  final String label;
  final bool available;
  const TimeSlot({required this.id, required this.label, this.available = true});
}

/// Tipo de entrega
enum DeliveryType { delivery, pickup }

/// Endereço do cliente
class Address {
  final String id;
  final String street, number, complement, neighborhood, city, state, cep;
  const Address({
    required this.id,
    required this.street,
    required this.number,
    this.complement = '',
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });

  String get short => '$street, $number';

  Address copyWith({
    String? id,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? cep,
  }) {
    return Address(
      id: id ?? this.id,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      cep: cep ?? this.cep,
    );
  }
}

/// Cupom de desconto
class Coupon {
  final String code;
  final double discount;
  const Coupon({required this.code, required this.discount});
}

/// Controlador principal do checkout
class CheckoutController extends ChangeNotifier {
  final ShippingService _shipping = ShippingService();

  // === ESTADO PRINCIPAL ===
  int currentStep = 1;
  DeliveryType deliveryType = DeliveryType.delivery;
  String? selectedAddressId;
  String selectedPickup = 'sion';
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  String paymentMethod = 'pix';
  String orderNotes = '';
  bool isSummaryExpanded = false;
  bool isLoading = false;
  bool isProcessing = false;
  String? orderId;
  String? pixCode;
  DateTime? pixExpiresAt;

  // === CUPOM ===
  Coupon? appliedCoupon;
  String couponCode = '';
  String? couponError;
  bool showCouponInput = false;
  bool isApplyingCoupon = false;

  // === TROCO ===
  bool needsChange = false;
  String changeForAmount = '';

  // === DADOS ===
  List<Address> addresses = [];
  double deliveryFee = 0.0;
  StoreInfo? storeInfo; // SALVA DO shipping_service
  OnboardingProfile? profile;

  // === TELEFONE ===
  String userPhone = '';
  bool isEditingPhone = false;

  // === LOCAIS DE RETIRADA ===
  final Map<String, Map<String, String>> pickupLocations = {
    'barreiro': {'name': 'Unidade Barreiro', 'address': 'Av. Sinfrônio Brochado, 612 - Barreiro'},
    'sion': {'name': 'Unidade Sion', 'address': 'R. Haití, 354 - Sion'},
    'central': {'name': 'Central Distribuição', 'address': 'Av. Silviano Brandão, 685 - Sagrada Família'},
    'lagosanta': {'name': 'Unidade Lagoa Santa', 'address': 'Av. Academico Nilo Figueiredo, 2303, Bela Vista', 'id': '131813'},
  };

  // === FERIADOS (funcionam como domingo) ===
  static final List<DateTime> holidays = [
    DateTime(2025, 1, 1),
    DateTime(2025, 3, 3),
    DateTime(2025, 3, 4),
    DateTime(2025, 3, 5),
    DateTime(2025, 4, 18),
    DateTime(2025, 4, 21),
    DateTime(2025, 5, 1),
    DateTime(2025, 6, 19),
    DateTime(2025, 9, 7),
    DateTime(2025, 10, 12),
    DateTime(2025, 11, 2),
    DateTime(2025, 11, 15),
    DateTime(2025, 11, 20),
    DateTime(2025, 12, 8),
  ];

  // === DIAS FECHADOS (25/12 e 01/01) ===
  static final List<DateTime> closedDays = [
    DateTime(2025, 12, 25),
    DateTime(2026, 1, 1),
  ];

  // === CÁLCULOS ===
  double get subtotal => CartController.instance.items.fold(0, (s, i) => s + i.product.price * i.quantity);

  double get total {
    final base = subtotal + deliveryFee;
    return appliedCoupon != null ? (base - appliedCoupon!.discount).clamp(0.0, double.infinity) : base;
  }

  // === CONSTRUTOR ===
  CheckoutController() {
    _bootstrap();
  }

  // === INICIALIZAÇÃO ===
  Future<void> _bootstrap() async {
    isLoading = true;
    try {
      final sp = await SharedPreferences.getInstance();
      final id = sp.getInt('customer_id');
      if (id != null) {
        profile = await OnboardingService().getProfile();
        addresses = _buildAddressesFromProfile();
        selectedAddressId = addresses.isNotEmpty ? addresses.first.id : null;
        userPhone = sp.getString('user_phone') ?? '';
        await _refreshFee();
      }
    } catch (e) {
      if (kDebugMode) print('Bootstrap error: $e');
    } finally {
      isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  List<Address> _buildAddressesFromProfile() {
    if (profile?.address == null) return [];
    final a = profile!.address!;
    return [
      Address(
        id: '1',
        street: a.street ?? '',
        number: a.number ?? '',
        complement: a.complement ?? '',
        neighborhood: a.neighborhood ?? '',
        city: a.city ?? '',
        state: a.state ?? '',
        cep: a.cep ?? '',
      ),
    ];
  }

  // === ENDEREÇO ===
  Future<void> addAddress(Address address) async {
    final newAddr = address.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    addresses.add(newAddr);
    selectedAddressId = newAddr.id;
    await _refreshFee();
    _safeNotify();
  }

  void selectAddress(String id) {
    selectedAddressId = id;
    _refreshFee();
    _safeNotify();
  }

  // === TIPO DE ENTREGA ===
  void setDeliveryType(DeliveryType type) {
    deliveryType = type;
    if (type == DeliveryType.pickup) deliveryFee = 0;
    _refreshFee();
    _safeNotify();
  }

  void selectPickup(String key) {
    selectedPickup = key;
    _safeNotify();
  }

  // === FRETE + LOJA (NOVO) ===
  Future<void> _refreshFee() async {
    if (deliveryType != DeliveryType.delivery || selectedAddressId == null) {
      deliveryFee = 0;
      storeInfo = null;
      _safeNotify();
      return;
    }

    try {
      final addr = addresses.firstWhere((a) => a.id == selectedAddressId);
      final result = await _shipping.fetchDeliveryFee(addr.cep);

      if (result != null) {
        deliveryFee = result.cost;
        storeInfo = result; // SALVA LOJA + ID
      } else {
        deliveryFee = 0;
        storeInfo = StoreInfo(name: 'Central Distribuição', id: '86261', cost: 0.0);
      }
    } catch (e) {
      deliveryFee = 0;
      storeInfo = StoreInfo(name: 'Central Distribuição', id: '86261', cost: 0.0);
    }
    _safeNotify();
  }

  // === NAVEGAÇÃO (RÁPIDA) ===
  Future<void> nextStep() async {
    if (currentStep == 1) {
      // Usa storeInfo do frete → 0ms
      if (storeInfo == null) {
        await _refreshFee(); // fallback
      }
      currentStep = 2;
    } else {
      await placeOrder();
    }
    _safeNotify();
  }

  void prevStep() {
    if (currentStep > 1) currentStep--;
    _safeNotify();
  }

  // === VALIDAÇÃO PARA PROSSEGUIR ===
  bool get canProceedToPayment {
    // 1. Telefone
    if (userPhone.isEmpty || userPhone.length < 10) return false;

    // 2. Endereço ou Retirada
    if (deliveryType == DeliveryType.delivery) {
      if (selectedAddressId == null || storeInfo == null) return false;
      final addr = addresses.firstWhere((a) => a.id == selectedAddressId);
      if (addr.street.isEmpty || addr.number.isEmpty || addr.cep.isEmpty) return false;
    } else {
      if (selectedPickup.isEmpty) return false;
    }

    // 3. Agendamento
    if (selectedDate == DateTime(0) || selectedTimeSlot == null) return false;

    // 4. Pagamento
    if (paymentMethod.isEmpty) return false;

    // 5. Troco
    if (needsChange && changeForAmount.isEmpty) return false;

    return true;
  }

  void goToPayment() {
    if (canProceedToPayment) nextStep();
  }

  // === CUPOM ===
  Future<void> applyCoupon(String code) async {
    isApplyingCoupon = true;
    couponError = null;
    _safeNotify();

    try {
      final url = 'https://aogosto.com.br/delivery/wp-json/wc/v3/coupons?code=${code.trim()}';
      final auth = base64Encode(utf8.encode('ck_5156e2360f442f2585c8c9a761ef084b710e811f:cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c'));
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': 'Basic $auth'});

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data.isNotEmpty && data[0]['status'] == 'publish') {
          final coupon = data[0];
          final amount = double.tryParse(coupon['amount'].toString()) ?? 0.0;
          final discount = coupon['discount_type'] == 'percent' ? subtotal * (amount / 100) : amount;
          appliedCoupon = Coupon(code: code.trim(), discount: discount);
          showCouponInput = false;
        } else {
          couponError = data.isEmpty ? 'Cupom não encontrado.' : 'Cupom inativo.';
        }
      } else {
        couponError = 'Erro ao validar cupom.';
      }
    } catch (e) {
      couponError = 'Erro ao validar cupom.';
    }

    isApplyingCoupon = false;
    _safeNotify();
  }

  void removeCoupon() {
    appliedCoupon = null;
    couponCode = '';
    couponError = null;
    _safeNotify();
  }

  // === TELEFONE ===
  void startEditPhone() {
    isEditingPhone = true;
    _safeNotify();
  }

  void cancelEditPhone() {
    isEditingPhone = false;
    _safeNotify();
  }

  Future<void> savePhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    userPhone = cleanPhone;
    isEditingPhone = false;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('user_phone', cleanPhone);
    _safeNotify();
  }

  // === PEDIDO REAL (SEM STORE DECISION) ===
  Future<void> placeOrder() async {
    isProcessing = true;
    _safeNotify();

    try {
      
      final sp = await SharedPreferences.getInstance();
    final customerId = sp.getInt('customer_id');
      // 1. LOJA DO FRETE (ou pickup)
      final effectiveStore = deliveryType == DeliveryType.pickup
          ? pickupLocations[selectedPickup]!['name']!
          : storeInfo?.name ?? 'Central Distribuição';
      final storeId = deliveryType == DeliveryType.pickup
          ? pickupLocations[selectedPickup]!['id'] ?? '86261'
          : storeInfo?.id ?? '86261';

      debugPrint('''
================================
CHECKOUT FINAL - LOJA
Loja: $effectiveStore
ID: $storeId
Tipo: ${deliveryType.name}
================================
''');

      // 2. LINE ITEMS
      final lineItems = CartController.instance.items.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
        };
      }).toList();

      // 3. ENDEREÇO
      final selectedAddr = addresses.firstWhere((a) => a.id == selectedAddressId);

      // 4. NOME
      final fullName = profile?.name?.trim() ?? "Cliente";
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : "Cliente";
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

      // 5. PAYLOAD
      final orderData = {
        "status": "pending",
        "created_via": "App",
        "billing": {
          "company": "App",
          "email": "app@aogosto.com.br",
          "first_name": firstName,
          "last_name": lastName,
          "phone": userPhone,
          "address_1": selectedAddr.street,
          "address_2": selectedAddr.complement,
          "city": selectedAddr.city,
          "state": selectedAddr.state,
          "postcode": selectedAddr.cep,
          "country": "BR"
        },
        "shipping": {
          "first_name": firstName,
          "last_name": lastName,
          "address_1": selectedAddr.street,
          "address_2": selectedAddr.complement,
          "city": selectedAddr.city,
          "state": selectedAddr.state,
          "postcode": selectedAddr.cep,
          "country": "BR"
        },
        "payment_method": _mapPaymentMethod(paymentMethod),
        "payment_method_title": _mapPaymentTitle(paymentMethod),
        "set_paid": false,
        "line_items": lineItems,
        "shipping_lines": deliveryType == DeliveryType.delivery
            ? [
                {
                  "method_id": "flat_rate",
                  "method_title": "Taxa de Entrega",
                  "total": deliveryFee.toStringAsFixed(2)
                }
              ]
            : [],
        "meta_data": [
          {"key": "_store_final", "value": effectiveStore},
          {"key": "_effective_store_final", "value": effectiveStore},
          {"key": "_shipping_pickup_store_id", "value": storeId},
          {"key": "_is_future_date", "value": _isFutureDate() ? "yes" : "no"},
          {"key": "delivery_type", "value": deliveryType == DeliveryType.delivery ? "delivery" : "pickup"},

          {"key": "_app_customer_id", "value": customerId?.toString() ?? ""},
          if (deliveryType == DeliveryType.delivery) ...[
            {"key": "delivery_date", "value": DateFormat('yyyy-MM-dd').format(selectedDate)},
            {"key": "delivery_time", "value": selectedTimeSlot}
          ] else ...[
            {"key": "pickup_date", "value": DateFormat('yyyy-MM-dd').format(selectedDate)},
            {"key": "pickup_time", "value": selectedTimeSlot},
            {"key": "_shipping_pickup_stores", "value": pickupLocations[selectedPickup]?['name'] ?? ''}
          ],
          if (needsChange) ...[
            {"key": "needs_change", "value": "yes"},
            {"key": "change_for_amount", "value": changeForAmount}
          ],
          if (orderNotes.isNotEmpty) {"key": "order_notes", "value": orderNotes}
        ]
      };

      // 6. ENVIA PARA WOOCOMMERCE
      final orderService = OrderService();
      final response = await orderService.createOrder(orderData);

      // 7. SUCESSO
      orderId = response['id'].toString();
      if (paymentMethod == 'pix') {
        pixCode = response['transaction_id'] ?? _generateMockPix();
        pixExpiresAt = DateTime.now().add(const Duration(minutes: 15));
      }

     final firestore = FirestoreService();
final mockOrder = Order(
  id: orderId!,
  date: DateTime.now(),
  status: 'Recebido',
  items: CartController.instance.items.map((i) => OrderItem(
    name: i.product.name,
    imageUrl: i.product.imageUrl,
    price: i.product.price,
    quantity: i.quantity,
  )).toList(),
  subtotal: subtotal,
  deliveryFee: deliveryFee,
  discount: appliedCoupon?.discount ?? 0,
  total: total,
  address: selectedAddr,
  payment: PaymentMethod(type: paymentMethod),
);
await firestore.saveOrder(mockOrder, customerId.toString());

  } catch (e) {
    print('Erro ao criar pedido: $e');
  } finally {
    isProcessing = false;
    _safeNotify();
  }
}

  // === MÉTODOS AUXILIARES ===
  String _mapPaymentMethod(String method) {
    switch (method) {
      case 'pix': return 'Pix';
      case 'card-online': return 'Cartão Crédito';
      case 'money': return 'Dinheiro';
      case 'card-on-delivery': return 'Cartão';
      case 'voucher': return 'V.A';
      default: return 'Pix';
    }
  }

  String _mapPaymentTitle(String method) {
    switch (method) {
      case 'pix': return 'Pix';
      case 'card-online': return 'Cartão Crédito';
      case 'money': return 'Dinheiro';
      case 'card-on-delivery': return 'Cartão na Entrega';
      case 'voucher': return 'Vale Alimentação';
      default: return 'Pix';
    }
  }

  bool _isFutureDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  String _generateMockPix() {
    return '00020126580014br.gov.bcb.pix2536e8b4af-e461-4a8c-9a4a-1f2b6e5e8e6f5204000053039865802BR5913Joao da Silva6009SAO PAULO62070503***6304E5B3';
  }

  // === UTILIDADES ===
  String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    if (digits.length == 10) return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    return phone;
  }

  // === SLOTS DE HORÁRIO (COM REGRAS) ===
  List<TimeSlot> getTimeSlots() {
    final today = DateTime.now();
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
    final isSunday = selectedDate.weekday == DateTime.sunday;
    final isHoliday = holidays.any((h) =>
        h.year == selectedDate.year &&
        h.month == selectedDate.month &&
        h.day == selectedDate.day);
    final isClosed = closedDays.any((c) =>
        c.year == selectedDate.year &&
        c.month == selectedDate.month &&
        c.day == selectedDate.day);

    if (isClosed) return [];

    List<String> slots;

    if (deliveryType == DeliveryType.pickup) {
      if (isSunday || isHoliday) {
        slots = ['09:00 - 12:00'];
      } else {
        slots = ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00'];
      }
    } else {
      if (isSunday || isHoliday) {
        slots = ['09:00 - 12:00'];
      } else {
        slots = ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00', '18:00 - 20:00'];
      }
    }

    if (isToday) {
      final now = today;
      slots = slots.where((slot) {
        final endTimeStr = slot.split(' - ')[1];
        final endHour = int.tryParse(endTimeStr.split(':')[0]) ?? 0;
        final endMinute = int.tryParse(endTimeStr.split(':')[1]) ?? 0;
        final slotEndTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          endHour,
          endMinute,
        );
        return slotEndTime.isAfter(now);
      }).toList();
    }

    return slots.map((label) => TimeSlot(id: label, label: label)).toList();
  }

  // === VERIFICA DATA INDISPONÍVEL ===
  static bool isDateUnavailable(DateTime date) {
    return holidays.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day) ||
        closedDays.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
  }

  // === NOTIFY SEGURO ===
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }
}