// lib/screens/checkout/checkout_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ao_gosto_app/models/customer_data.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/models/order_model.dart'; 
import 'package:ao_gosto_app/api/shipping_service.dart';
import 'package:ao_gosto_app/api/firestore_service.dart';
import 'package:ao_gosto_app/api/order_service.dart';
import 'package:ao_gosto_app/services/pagarme_service.dart';
import 'package:ao_gosto_app/config/pagarme_credentials.dart';


/// Modelo de slot de horário
class TimeSlot {
  final String id;
  final String label;
  final bool available;
  const TimeSlot({required this.id, required this.label, this.available = true});
}

/// Tipo de entrega
enum DeliveryType { delivery, pickup }


/// ===============================================================
///    ENDEREÇO DO CHECKOUT  (Não é o do pedido!)
/// ===============================================================
class CheckoutAddress {
  final String id;
  final String street, number, complement, neighborhood, city, state, cep;

  const CheckoutAddress({
    required this.id,
    required this.street,
    required this.number,
    this.complement = '',
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });

  CheckoutAddress copyWith({
    String? id,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? cep,
  }) {
    return CheckoutAddress(
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

  String get short => '$street, $number';
}



/// Cupom de desconto
class Coupon {
  final String code;
  final double discount;
  const Coupon({required this.code, required this.discount});
}

/// ===============================================================
///              CONTROLADOR PRINCIPAL DO CHECKOUT
/// ===============================================================
class CheckoutController extends ChangeNotifier {
  final ShippingService _shipping = ShippingService();

  // === ESTADO PRINCIPAL ===
  int currentStep = 1;
  DeliveryType deliveryType = DeliveryType.delivery;
  String? selectedAddressId;
  String selectedPickup = 'sion';
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  
  // ✅ PAYMENTMETHOD COM SETTER QUE NOTIFICA
  String _paymentMethod = 'pix';
  String get paymentMethod => _paymentMethod;
  set paymentMethod(String value) {
    _paymentMethod = value;
    notifyListeners(); // ✅ NOTIFICA OS LISTENERS
  }
  
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
  List<CheckoutAddress> addresses = [];
  double deliveryFee = 0.0;
  StoreInfo? storeInfo;

  // === TELEFONE ===
  String userPhone = '';
  bool isEditingPhone = false;

  // === LOCAIS DE RETIRADA ===
  final Map<String, Map<String, String>> pickupLocations = {
    'barreiro': {
      'name': 'Unidade Barreiro',
      'address': 'Av. Sinfrônio Brochado, 612 - Barreiro',
      'id': '110727'
    },
    'sion': {
      'name': 'Unidade Sion',
      'address': 'R. Haití, 354 - Sion',
      'id': '12'
    },
    'central': {
      'name': 'Central Distribuição (Sagrada Família)',
      'address': 'Av. Silviano Brandão, 685 - Sagrada Família',
      'id': '86261'
    },
    'lagosanta': {
      'name': 'Unidade Lagoa Santa',
      'address': 'Av. Academico Nilo Figueiredo, 2303, Bela Vista',
      'id': '131813'
    },
  };

  // ✅ GETTER PARA O TEXTO DO BOTÃO (ADICIONE ESTE GETTER)
  String get finalizarButtonText {
    if (currentStep == 1) {
      return 'Continuar';
    }
    
    if (_paymentMethod == 'pix') {
      final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
      return 'Gerar PIX de ${currency.format(total)}';
    }
    
    // Cartão, Dinheiro, Vale → "Pagar na Entrega"
    return 'Pagar na Entrega';
  }

  // === FERIADOS ===
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


  double get subtotal =>
      CartController.instance.items.fold(0, (s, i) => s + i.product.price * i.quantity);

  double get total {
    final base = subtotal + deliveryFee;
    return appliedCoupon != null
        ? (base - appliedCoupon!.discount).clamp(0.0, double.infinity)
        : base;
  }




  /// ===========================================================
  ///                     CONSTRUTOR
  /// ===========================================================
  CheckoutController() {
    _bootstrap();
  }


  /// ===========================================================
  ///             INICIALIZAÇÃO DO CHECKOUT (VERSÃO FINAL)
  /// ===========================================================
  Future<void> _bootstrap() async {
    isLoading = true;
    notifyListeners();

    try {
      final customerProv = CustomerProvider.instance;

      // Se o cliente ainda não foi carregado, tenta carregar do SharedPreferences como fallback
      if (customerProv.customer == null) {
        final sp = await SharedPreferences.getInstance();
        final phone = sp.getString('customer_phone');
        final name = sp.getString('customer_name');

        if (phone != null && name != null && phone.isNotEmpty) {
          // Tenta carregar do Firestore usando o telefone como UID
          await customerProv.loadOrCreateCustomer(
            name: name,
            phone: phone,
          );
        }
      }

      // Agora sim, usa o cliente do Provider
      final customer = customerProv.customer;
      if (customer == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      // Converte endereços do Firestore → CheckoutAddress
      addresses = customer.addresses.map((a) {
        return CheckoutAddress(
          id: a.id,
          street: a.street,
          number: a.number,
          complement: a.complement ?? '',
          neighborhood: a.neighborhood,
          city: a.city,
          state: a.state,
          cep: a.cep,
        );
      }).toList();

      // Seleciona o endereço padrão ou o primeiro
      final defaultAddress = customer.addresses.firstWhereOrNull((a) => a.isDefault);
      selectedAddressId = defaultAddress?.id ?? addresses.firstOrNull?.id;

      // Telefone formatado para exibir
      userPhone = _formatPhone(customer.phone);

      // Atualiza frete se tiver endereço selecionado
      if (selectedAddressId != null) {
        await _refreshFee();
      }
    } catch (e) {
      debugPrint("Erro no bootstrap do checkout: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // Método auxiliar pra formatar telefone
  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return phone;
  }
 

  // ===========================================================
  //                        ENDEREÇOS
  // ===========================================================
  // === ADICIONAR ENDEREÇO (ATUALIZADO) ===
Future<void> addAddress(CheckoutAddress address) async {
  final newAddr = address.copyWith(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
  );

  // ✅ 1. Adiciona localmente (para uso imediato no checkout)
  addresses.add(newAddr);
  selectedAddressId = newAddr.id;

  // ✅ 2. Sincroniza com Firestore via CustomerProvider
  final customerProv = CustomerProvider.instance;
  if (customerProv.customer != null) {
    final customerAddress = CustomerAddress(
      id: newAddr.id,
      apelido: "Minha Casa", // Você pode pedir ao usuário
      street: newAddr.street,
      number: newAddr.number,
      complement: newAddr.complement.isEmpty ? null : newAddr.complement,
      neighborhood: newAddr.neighborhood,
      city: newAddr.city,
      state: newAddr.state,
      cep: newAddr.cep,
      isDefault: addresses.length == 1, // Primeiro endereço = padrão
    );
    
    await customerProv.saveAddress(
      customerAddress,
      setAsDefault: addresses.length == 1,
    );
  }

  await _refreshFee();
  _safeNotify();
}



Future<void> selectAddress(String id) async {
  selectedAddressId = id;
  
  // ✅ OPCIONAL: Marca como padrão no Firestore
  final customerProv = CustomerProvider.instance;
  if (customerProv.customer != null) {
    final selectedAddr = addresses.firstWhere((a) => a.id == id);
    final customerAddress = CustomerAddress(
      id: selectedAddr.id,
      apelido: "Endereço Padrão",
      street: selectedAddr.street,
      number: selectedAddr.number,
      complement: selectedAddr.complement.isEmpty ? null : selectedAddr.complement,
      neighborhood: selectedAddr.neighborhood,
      city: selectedAddr.city,
      state: selectedAddr.state,
      cep: selectedAddr.cep,
      isDefault: true,
    );
    
    await customerProv.saveAddress(
      customerAddress,
      setAsDefault: true, // ✅ Marca como padrão
    );
  }
  
  _refreshFee();
  _safeNotify();
}


  // ===========================================================
  //                   ENTREGA OU RETIRADA
  // ===========================================================
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



  // ===========================================================
  //                         FRETE
  // ===========================================================
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
        storeInfo = result;
      } else {
        deliveryFee = 0;
        storeInfo = StoreInfo(
          name: 'Central Distribuição',
          id: '86261',
          cost: 0.0,
        );
      }
    } catch (e) {
      deliveryFee = 0;
      storeInfo = StoreInfo(
        name: 'Central Distribuição',
        id: '86261',
        cost: 0.0,
      );
    }

    _safeNotify();
  }



  // ===========================================================
  //                FLUXO DE NAVEGAÇÃO NO CHECKOUT
  // ===========================================================
  Future<void> nextStep() async {
    if (currentStep == 1) {
      if (storeInfo == null) {
        await _refreshFee();
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



  // ===========================================================
  //                   VALIDAÇÃO DAS ETAPAS
  // ===========================================================
  bool get canProceedToPayment {
    if (userPhone.isEmpty || userPhone.length < 10) return false;

    if (deliveryType == DeliveryType.delivery) {
      if (selectedAddressId == null || storeInfo == null) return false;

      final addr = addresses.firstWhere((a) => a.id == selectedAddressId);

      if (addr.street.isEmpty || addr.number.isEmpty || addr.cep.isEmpty) {
        return false;
      }
    }
    else {
      if (selectedPickup.isEmpty) return false;
    }

    if (selectedDate == DateTime(0) || selectedTimeSlot == null) return false;

    if (paymentMethod.isEmpty) return false;

    if (needsChange && changeForAmount.isEmpty) return false;

    return true;
  }

  void goToPayment() {
    if (canProceedToPayment) nextStep();
  }


  // ===========================================================
  //                     CUPOM DE DESCONTO
  // ===========================================================
  Future<void> applyCoupon(String code) async {
    isApplyingCoupon = true;
    couponError = null;
    _safeNotify();

    try {
      final url = 'https://aogosto.com.br/delivery/wp-json/wc/v3/coupons?code=${code.trim()}';
      final auth = base64Encode(utf8.encode(
          'ck_5156e2360f442f2585c8c9a761ef084b710e811f:cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c'));

      final resp = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Basic $auth'},
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);

        if (data.isNotEmpty && data[0]['status'] == 'publish') {
          final coupon = data[0];

          final amount =
              double.tryParse(coupon['amount'].toString()) ?? 0.0;

          final discount =
              coupon['discount_type'] == 'percent'
                  ? subtotal * (amount / 100)
                  : amount;

          appliedCoupon = Coupon(
            code: code.trim(),
            discount: discount,
          );

          showCouponInput = false;
        } else {
          couponError =
              data.isEmpty ? 'Cupom não encontrado.' : 'Cupom inativo.';
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




  // ===========================================================
  //                       TELEFONE
  // ===========================================================
  void startEditPhone() {
    isEditingPhone = true;
    _safeNotify();
  }

  void cancelEditPhone() {
    isEditingPhone = false;
    _safeNotify();
  }

  // === SALVAR TELEFONE (ATUALIZADO) ===
Future<void> savePhone(String phone) async {
  final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
  userPhone = cleanPhone;
  isEditingPhone = false;

  // ✅ 1. Salva no SharedPreferences COM A CHAVE CORRETA
  final sp = await SharedPreferences.getInstance();
  await sp.setString('customer_phone', cleanPhone);  // ✅ CORRIGIDO!

  // ✅ 2. Atualiza no Firestore via CustomerProvider
  final customerProv = CustomerProvider.instance;
  if (customerProv.customer != null) {
    final updated = customerProv.customer!.copyWith(phone: cleanPhone);
    await customerProv.updateCustomer(updated);
  }

  _safeNotify();
}

  // ===========================================================
  //                     FINALIZAÇÃO DO PEDIDO
  // ===========================================================
  // lib/screens/checkout/checkout_controller.dart

Future<void> placeOrder() async {
  isProcessing = true;
  _safeNotify();

  try {
    final sp = await SharedPreferences.getInstance();
    final customerId = sp.getString('customer_id');

    // ✅ 1. DETERMINAR LOJA FINAL
    final effectiveStoreId = _getEffectiveStoreId();
    final effectiveStoreName = _getEffectiveStoreName(effectiveStoreId);

    debugPrint('''
====================================
CHECKOUT FINAL
Loja: $effectiveStoreName
Loja ID: $effectiveStoreId
Tipo: ${deliveryType.name}
====================================
''');

    final lineItems = CartController.instance.items.map((item) {
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    final selectedAddr = addresses.firstWhere((a) => a.id == selectedAddressId);
    final customer = CustomerProvider.instance.customer;
    final fullName = customer?.name ?? "Cliente";
    final userPhoneRaw = customer?.phone ?? userPhone.replaceAll(RegExp(r'\D'), '');
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : "Cliente";
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";
    await sp.setString('customer_phone', userPhoneRaw);

    // ✅ 2. CRIAR PEDIDO NO WOOCOMMERCE
    final orderData = {
      "status": paymentMethod == 'pix' ? "pending" : "processing",
      "created_via": "App",

      "billing": {
        "company": "App",
        "email": "app@aogosto.com.br",
        "first_name": firstName,
        "last_name": lastName,
        "phone": userPhoneRaw,
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
        {"key": "_store_final", "value": effectiveStoreName},
        {"key": "_effective_store_final", "value": effectiveStoreName},
        {"key": "_shipping_pickup_store_id", "value": effectiveStoreId},
        {"key": "_processed_by_app", "value": "true"},

        {
          "key": "_is_future_date",
          "value": _isFutureDate() ? "yes" : "no"
        },

        {
          "key": "delivery_type",
          "value": deliveryType == DeliveryType.delivery ? "delivery" : "pickup"
        },

        {
          "key": "_app_customer_id",
          "value": customerId?.toString() ?? ""
        },

        if (deliveryType == DeliveryType.delivery) ...[
          {
            "key": "delivery_date",
            "value": DateFormat('yyyy-MM-dd').format(selectedDate)
          },
          {"key": "delivery_time", "value": selectedTimeSlot}
        ] else ...[
          {
            "key": "pickup_date",
            "value": DateFormat('yyyy-MM-dd').format(selectedDate)
          },
          {"key": "pickup_time", "value": selectedTimeSlot},
          {
            "key": "_shipping_pickup_stores",
            "value": pickupLocations[selectedPickup]?['name'] ?? ''
          }
        ],

        if (needsChange) ...[
          {"key": "needs_change", "value": "yes"},
          {"key": "change_for_amount", "value": changeForAmount}
        ],

        if (orderNotes.isNotEmpty)
          {"key": "order_notes", "value": orderNotes}
      ]
    };

    final orderService = OrderService();
    final response = await orderService.createOrder(orderData);

    orderId = response['id'].toString();

    // ✅ 3. SE PIX, GERAR NO PAGAR.ME
    if (paymentMethod == 'pix') {
      debugPrint('🔥 Gerando PIX no Pagar.me para pedido #$orderId');

      final pagarmeService = PagarMeService();

      try {
        final pixResponse = await pagarmeService.generatePix(
          orderId: orderId!,
          storeFinal: effectiveStoreName,
          totalAmount: total,
          customerPhone: userPhoneRaw,
        );

        pixCode = pixResponse.qrCodeText;
        pixExpiresAt = pixResponse.expiresAt;

        debugPrint('✅ PIX gerado com sucesso!');
        debugPrint('QR Code: ${pixCode?.substring(0, 50)}...');
        debugPrint('Expira em: $pixExpiresAt');
      } catch (e) {
        debugPrint('❌ Erro ao gerar PIX: $e');
        // Fallback para mock caso dê erro
        pixCode = _generateMockPix();
        pixExpiresAt = DateTime.now().add(const Duration(minutes: 60));
      }
    }

    /// =======================================================
    ///  4. SALVAR NO FIRESTORE
    /// =======================================================
    final firestore = FirestoreService();
    String cd = _getCdName(effectiveStoreName);

    final String janelaTexto = selectedTimeSlot ?? "Horário não definido";
    final bool isAgendado = _isFutureDate();

    // ✅ LÓGICA DE STATUS CORRIGIDA
    String statusFinal;

    if (paymentMethod == 'pix') {
      // PIX sempre começa como "Pendente" (independente da data)
      statusFinal = "Pendente";
      debugPrint('💳 Pedido $orderId: PIX não pago → Status: Pendente');
    } else if (isAgendado) {
      // Pagamento na entrega + Data futura = Agendado
      statusFinal = "Agendado";
      debugPrint('📅 Pedido $orderId: Pagamento na entrega + Data futura → Status: Agendado');
    } else {
      // Pagamento na entrega + Data hoje = Processando
      statusFinal = "Processando";
      debugPrint('✅ Pedido $orderId: Pagamento na entrega + Data hoje → Status: Processando');
    }

    final mockOrder = AppOrder(
      id: orderId!,
      date: selectedDate,
      status: statusFinal,  // ✅ STATUS CORRETO
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
      address: Address(
        id: selectedAddr.id,
        street: selectedAddr.street,
        number: selectedAddr.number,
        complement: selectedAddr.complement,
        neighborhood: selectedAddr.neighborhood,
        city: selectedAddr.city,
        state: selectedAddr.state,
        cep: selectedAddr.cep,
      ),
      payment: PaymentMethod(type: paymentMethod),
      rating: null,
    );

    await firestore.saveOrder(
      mockOrder,
      userPhoneRaw,
      cd: cd,
      janelaTexto: janelaTexto,
      isAgendado: isAgendado,
      customerName: customer?.name ?? 'Cliente',
    );

    debugPrint('✅ Pedido $orderId salvo no Firestore com status: $statusFinal');
  } catch (e) {
    debugPrint('❌ Erro ao criar pedido: $e');
  } finally {
    isProcessing = false;
    _safeNotify();
  }
}

  Future<void> refreshFee() async {
    await _refreshFee();
    _safeNotify();
  }

  // ===========================================================
  //                     MÉTODOS AUXILIARES
  // ===========================================================
  
  /// Retorna o ID da loja efetiva
  String _getEffectiveStoreId() {
    if (deliveryType == DeliveryType.pickup) {
      return pickupLocations[selectedPickup]?['id'] ?? '86261';
    }
    return storeInfo?.id ?? '86261';
  }

  /// Retorna o nome completo da loja (para metadados Pagar.me)
  String _getEffectiveStoreName(String storeId) {
    // Tenta pegar do mapeamento
    final mappedName = PagarMeCredentials.getStoreNameById(storeId);
    
    // Se não encontrou no mapeamento, usa o nome do storeInfo ou pickup
    if (mappedName == 'Central Distribuição (Sagrada Família)' && storeInfo != null) {
      // Verifica se o nome do storeInfo é diferente do padrão
      if (storeInfo!.name != 'Central Distribuição') {
        return storeInfo!.name;
      }
    }
    
    // Se for pickup, usa o nome do local
    if (deliveryType == DeliveryType.pickup) {
      return pickupLocations[selectedPickup]?['name'] ?? mappedName;
    }
    
    return mappedName;
  }

  /// Converte nome da loja para CD (para Firestore)
  String _getCdName(String storeName) {
    if (storeName.contains("Sion")) return "CD Sion";
    if (storeName.contains("Barreiro")) return "CD Barreiro";
    if (storeName.contains("Lagoa Santa")) return "CD Lagoa Santa";
    return "CD Central";
  }
  
  String _mapPaymentMethod(String method) {
    switch (method) {
      case 'pix':
        return 'Pix';
      case 'card-online':
        return 'Cartão Crédito';
      case 'money':
        return 'Dinheiro';
      case 'card-on-delivery':
        return 'Cartão';
      case 'voucher':
        return 'V.A';
      default:
        return 'Pix';
    }
  }

  String _mapPaymentTitle(String method) {
    switch (method) {
      case 'pix':
        return 'Pix';
      case 'card-online':
        return 'Cartão Crédito';
      case 'money':
        return 'Dinheiro';
      case 'card-on-delivery':
        return 'Cartão na Entrega';
      case 'voucher':
        return 'Vale Alimentação';
      default:
        return 'Pix';
    }
  }

  bool _isFutureDate() {
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);

    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    return selected.isAfter(today);
  }


  String _generateMockPix() {
    return '00020126580014br.gov.bcb.pix2536e8b4af-e461-4a8c-9a4a-1f2b6e5e8e6f5204000053039865802BR5913Joao da Silva6009SAO PAULO62070503***6304E5B3';
  }


  String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }

    return phone;
  }

  String _mapMetodoPrincipal(String method) {
    switch (method) {
      case 'pix': return 'Pix';
      case 'money': return 'Dinheiro';
      case 'card-on-delivery': return 'Cartão';
      case 'card-online': return 'Crédito Site';
      case 'voucher': return 'V.A';
      default: return 'Pix';
    }
  }



  // ===========================================================
  //                     SLOTS DE HORÁRIO
  // ===========================================================
  List<TimeSlot> getTimeSlots() {
    final today = DateTime.now();

    final isToday =
        selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final isSunday =
        selectedDate.weekday == DateTime.sunday;

    final isHoliday =
        holidays.any((h) =>
            h.year == selectedDate.year &&
            h.month == selectedDate.month &&
            h.day == selectedDate.day);

    final isClosed =
        closedDays.any((c) =>
            c.year == selectedDate.year &&
            c.month == selectedDate.month &&
            c.day == selectedDate.day);


    if (isClosed) return [];

    List<String> slots;


    if (deliveryType == DeliveryType.pickup) {
      if (isSunday || isHoliday) {
        slots = ['09:00 - 12:00'];
      } else {
        slots = [
          '09:00 - 12:00',
          '12:00 - 15:00',
          '15:00 - 18:00'
        ];
      }
    }
    else {
      if (isSunday || isHoliday) {
        slots = ['09:00 - 12:00'];
      } else {
        slots = [
          '09:00 - 12:00',
          '12:00 - 15:00',
          '15:00 - 18:00',
          '18:00 - 20:00'
        ];
      }
    }


    if (isToday) {
      final now = today;

      slots = slots.where((slot) {
        final endTimeStr = slot.split(' - ')[1];

        final endHour =
            int.tryParse(endTimeStr.split(':')[0]) ?? 0;

        final endMinute =
            int.tryParse(endTimeStr.split(':')[1]) ?? 0;


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

    return slots
        .map((label) => TimeSlot(id: label, label: label))
        .toList();
  }



  // ===========================================================
  //                 DATAS INDISPONÍVEIS
  // ===========================================================
  static bool isDateUnavailable(DateTime date) {
    return holidays.any((d) =>
            d.year == date.year &&
            d.month == date.month &&
            d.day == date.day) ||
        closedDays.any((d) =>
            d.year == date.year &&
            d.month == date.month &&
            d.day == date.day);
  }



  // ===========================================================
  //                     NOTIFY SEGURO
  // ===========================================================
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }
}