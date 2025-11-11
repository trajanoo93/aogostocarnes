// lib/screens/checkout/checkout_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/api/shipping_service.dart';
import 'package:ao_gosto_app/api/onboarding_service.dart';
import 'package:ao_gosto_app/api/order_service.dart';

class TimeSlot {
  final String id;
  final String label;
  final bool available;
  const TimeSlot({required this.id, required this.label, this.available = true});
}

enum DeliveryType { delivery, pickup }

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

class StoreDecision {
  final String storeFinal;
  final String effectiveStore;
  final String storeId;
  final List<Map<String, dynamic>> paymentMethods;
  final Map<String, String> paymentAccounts;
  StoreDecision({
    required this.storeFinal,
    required this.effectiveStore,
    required this.storeId,
    required this.paymentMethods,
    required this.paymentAccounts,
  });
}

class Coupon {
  final String code;
  final double discount;
  const Coupon({required this.code, required this.discount});
}

class CheckoutController extends ChangeNotifier {
  final ShippingService _shipping = ShippingService();
  final String _storeDecisionUrl = 'https://aogosto.com.br/delivery/wp-json/custom/v1/store-decision';

  // === STATE ===
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
  StoreDecision? storeDecision;
  OnboardingProfile? profile;

  // === TELEFONE ===
  String userPhone = '';
  bool isEditingPhone = false;

  // === PICKUP LOCATIONS ===
  final Map<String, Map<String, String>> pickupLocations = {
    'barreiro': {'name': 'Unidade Barreiro', 'address': 'Av. Sinfrônio Brochado, 612 - Barreiro'},
    'sion': {'name': 'Unidade Sion', 'address': 'R. Haití, 354 - Sion'},
    'central': {'name': 'Central Distribuição', 'address': 'Av. Silviano Brandão, 685 - Sagrada Família'},
  };

  // === FERIADOS E FECHAMENTOS (NÃO PODEM SER const) ===
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

  static final List<DateTime> closedDays = [
    DateTime(2025, 12, 25),
    DateTime(2026, 1, 1),
  ];

  // === COMPUTED ===
  double get subtotal => CartController.instance.items.fold(0, (s, i) => s + i.product.price * i.quantity);
  double get total {
    final base = subtotal + deliveryFee;
    return appliedCoupon != null ? (base - appliedCoupon!.discount).clamp(0.0, double.infinity) : base;
  }

  CheckoutController() {
    _bootstrap();
  }

  // === BOOTSTRAP SEGURO ===
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
    notifyListeners();
  }

  // === ENTREGA/RETIRADA ===
  void setDeliveryType(DeliveryType type) {
    deliveryType = type;
    if (type == DeliveryType.pickup) deliveryFee = 0;
    _refreshFee();
    notifyListeners();
  }

  void selectPickup(String key) {
    selectedPickup = key;
    _safeNotify();
  }

  // === FRETE ===
  Future<void> _refreshFee() async {
    if (deliveryType != DeliveryType.delivery || selectedAddressId == null) {
      deliveryFee = 0;
      _safeNotify();
      return;
    }
    try {
      final addr = addresses.firstWhere((a) => a.id == selectedAddressId);
      deliveryFee = await _shipping.fetchDeliveryFee(addr.cep);
    } catch (e) {
      deliveryFee = 0;
    }
    _safeNotify();
  }

  // === NAVEGAÇÃO ===
  Future<void> nextStep() async {
    if (currentStep == 1) {
      await callStoreDecision();
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

  // === STORE DECISION ===
  Future<void> callStoreDecision() async {
    final addr = addresses.firstWhere(
      (a) => a.id == selectedAddressId,
      orElse: () => addresses.first,
    );
    final body = {
      'cep': addr.cep,
      'shipping_method': deliveryType == DeliveryType.delivery ? 'delivery' : 'pickup',
      'pickup_store': deliveryType == DeliveryType.pickup ? selectedPickup : '',
      'delivery_date': selectedDate.toIso8601String().split('T').first,
    };
    try {
      final resp = await http.post(
        Uri.parse(_storeDecisionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        storeDecision = StoreDecision(
          storeFinal: data['store_final'],
          effectiveStore: data['effective_store_final'],
          storeId: data['pickup_store_id'],
          paymentMethods: List<Map<String, dynamic>>.from(data['payment_methods']),
          paymentAccounts: Map<String, String>.from(data['payment_accounts']),
        );
      }
    } catch (e) {
      storeDecision = StoreDecision(
        storeFinal: 'Central',
        effectiveStore: 'Central',
        storeId: '86261',
        paymentMethods: [],
        paymentAccounts: {},
      );
    }
    _safeNotify();
  }

  // === VALIDAÇÃO ===
  bool get canProceedToPayment {
    if (userPhone.isEmpty) return false;
    return deliveryType == DeliveryType.delivery ? selectedAddressId != null : selectedPickup.isNotEmpty;
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
  void startEditPhone() => isEditingPhone = true;
  void cancelEditPhone() => isEditingPhone = false;

  Future<void> savePhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    userPhone = cleanPhone;
    isEditingPhone = false;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('user_phone', cleanPhone);
    _safeNotify();
  }

  // === PEDIDO ===
  Future<void> placeOrder() async {
    isProcessing = true;
    _safeNotify();

    await Future.delayed(const Duration(milliseconds: 1500));
    orderId = '${DateTime.now().millisecondsSinceEpoch}'.substring(6);
    pixCode = '00020126580014br.gov.bcb.pix2536e8b4af-e461-4a8c-9a4a-1f2b6e5e8e6f5204000053039865802BR5913Joao da Silva6009SAO PAULO62070503***6304E5B3';
    pixExpiresAt = DateTime.now().add(const Duration(minutes: 15));

    isProcessing = false;
    _safeNotify();
  }

  // === UTILIDADES ===
  String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    if (digits.length == 10) return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    return phone;
  }

  // === SLOTS COM REGRAS (CORRIGIDO) ===
  List<TimeSlot> getTimeSlots() {
    final today = DateTime.now();
    final isToday = this.selectedDate.year == today.year &&
        this.selectedDate.month == today.month &&
        this.selectedDate.day == today.day;
    final isSunday = this.selectedDate.weekday == DateTime.sunday;
    final isHoliday = holidays.any((h) =>
        h.year == this.selectedDate.year &&
        h.month == this.selectedDate.month &&
        h.day == this.selectedDate.day);
    final isClosed = closedDays.any((c) =>
        c.year == this.selectedDate.year &&
        c.month == this.selectedDate.month &&
        c.day == this.selectedDate.day);

    if (isClosed) return [];

    List<String> slots;

    if (this.deliveryType == DeliveryType.pickup || isSunday || isHoliday) {
  slots = ['09:00 - 12:00'];
} else {
  slots = ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00', '18:00 - 20:00']; 
}

    if (isToday) {
      final hour = today.hour;
      slots = slots.where((s) {
        final endHour = int.tryParse(s.split(' - ')[1].split(':')[0]) ?? 0;
        return endHour > hour;
      }).toList();
    }

    return slots.map((label) => TimeSlot(id: label, label: label)).toList();
  }

  // === MÉTODO ESTÁTICO PARA VERIFICAR DATAS INDISPONÍVEIS ===
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