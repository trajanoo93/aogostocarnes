import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:aogosto_carnes_flutter/state/cart_controller.dart';
import 'package:aogosto_carnes_flutter/api/shipping_service.dart';
import 'package:aogosto_carnes_flutter/api/onboarding_service.dart';

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

  // Contato
  String userPhone = '';
  bool isEditingPhone = false;

  // Endereços e retirada
  List<Address> addresses = const [];
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
      final profile = await OnboardingService().getProfile(); // já existe no seu app
      userPhone = profile.phone ?? userPhone;

      // monta address com base no que você salvou (adapte se seu perfil tiver estrutura diferente)
      final addrs = <Address>[];
      if (profile.address != null) {
        final a = profile.address!;
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

      // calcula frete se delivery e tem CEP
      if (deliveryType == DeliveryType.delivery && addresses.isNotEmpty) {
        await refreshShippingFee();
      }
    } catch (_) {
      // fallback silencioso
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
    userPhone = raw;
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
    await Future.delayed(const Duration(milliseconds: 800));
    if (couponCode.trim().toUpperCase() == 'AOGOSTO20') {
      appliedCoupon = const Coupon(code: 'AOGOSTO20', discount: 20.0);
      showCouponInput = false;
      couponCode = '';
    } else {
      couponError = 'Cupom inválido ou expirado.';
    }
    isApplyingCoupon = false;
    notifyListeners();
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
    } else {
      // “real” submit virá depois; por agora, simula sucesso
      orderPlaced = true;
    }
    notifyListeners();
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
      orElse: () => addresses.isNotEmpty ? addresses.first : Address(
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
}
