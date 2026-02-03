// lib/services/remote_config_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static const String _configUrl = 'https://aogosto.com.br/app/oms/api.php';
  static const String _cacheKey = 'remote_config_cache';
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  static RemoteConfig? _cachedConfig;
  static DateTime? _lastFetch;

  static Future<RemoteConfig> fetchConfig({bool forceRefresh = false}) async {
    try {
      // ✅ Retorna cache se ainda válido
      if (!forceRefresh && _cachedConfig != null && _lastFetch != null) {
        final now = DateTime.now();
        if (now.difference(_lastFetch!) < _cacheDuration) {
          debugPrint('🔵 Remote Config: Usando cache (válido por mais ${_cacheDuration.inMinutes - now.difference(_lastFetch!).inMinutes} min)');
          return _cachedConfig!;
        }
      }

      debugPrint('🔵 Buscando Remote Config de: $_configUrl');
      
      final response = await http.get(Uri.parse(_configUrl)).timeout(
        const Duration(seconds: 10),
      );

      debugPrint('📡 Status da API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Converter JSON para Objeto com proteções extras
        final config = RemoteConfig.fromJson(jsonData);
        
        // ✅ Salva no cache em memória
        _cachedConfig = config;
        _lastFetch = DateTime.now();
        
        // ✅ Salva no cache local (SharedPreferences)
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_cacheKey, response.body);
        
        debugPrint('✅ Remote Config carregado com sucesso!');
        debugPrint('   App Enabled: ${config.appEnabled}');
        debugPrint('   WhatsApp: ${config.whatsappNumber}');
        
        return config;
      } else {
        debugPrint('⚠️ API retornou status ${response.statusCode}');
        return _loadFromCache();
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar Remote Config: $e');
      return _loadFromCache();
    }
  }

  static Future<RemoteConfig> _loadFromCache() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final cachedJson = sp.getString(_cacheKey);
      
      if (cachedJson != null) {
        debugPrint('📦 Usando Remote Config do cache local');
        final config = RemoteConfig.fromJson(json.decode(cachedJson));
        _cachedConfig = config;
        return config;
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar cache: $e');
    }
    
    debugPrint('🔴 Usando configuração padrão (fallback total)');
    return RemoteConfig.defaultConfig();
  }
}

// ═══════════════════════════════════════════════════════════
//                    MODELO REMOTE CONFIG
// ═══════════════════════════════════════════════════════════
class RemoteConfig {
  final bool appEnabled;
  final String maintenanceMessage;
  final bool showChristmasCarousel;
  final SlotsConfig slotsConfig;
  final CustomMessage customMessage;
  final Features features;
  final Map<String, bool> pickupStores;
  final String whatsappNumber;
  final DateTime updatedAt;

  const RemoteConfig({
    required this.appEnabled,
    required this.maintenanceMessage,
    required this.showChristmasCarousel,
    required this.slotsConfig,
    required this.customMessage,
    required this.features,
    required this.pickupStores,
    required this.whatsappNumber,
    required this.updatedAt,
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      appEnabled: json['app_enabled'] ?? true,
      maintenanceMessage: json['maintenance_message'] ?? 'Estamos em manutenção.',
      showChristmasCarousel: json['show_christmas_carousel'] ?? false,
      
      // ✅ CORREÇÃO 1: Verifica se slots_config é um Map válido antes de processar
      slotsConfig: (json['slots_config'] is Map<String, dynamic>)
          ? SlotsConfig.fromJson(json['slots_config'])
          : SlotsConfig.defaultConfig(),

      customMessage: CustomMessage.fromJson(json['custom_message'] ?? {}),
      features: Features.fromJson(json['features'] ?? {}),
      
      // ✅ CORREÇÃO 2: Verifica se pickup_stores é Map. Se o PHP mandar [] (vazio), usa o padrão.
      pickupStores: (json['pickup_stores'] is Map)
          ? Map<String, bool>.from(json['pickup_stores'])
          : {
              'barreiro': true,
              'sion': true,
              'central': true,
              'lagosanta': true,
            },
      
      whatsappNumber: json['whatsapp_number'] ?? '5531997682271',
      
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  factory RemoteConfig.defaultConfig() {
    return RemoteConfig(
      appEnabled: true,
      maintenanceMessage: 'Estamos em manutenção. Voltamos em breve! 🛠️',
      showChristmasCarousel: false,
      slotsConfig: SlotsConfig.defaultConfig(),
      customMessage: CustomMessage.defaultConfig(),
      features: Features.defaultConfig(),
      pickupStores: {
        'barreiro': true,
        'sion': true,
        'central': true,
        'lagosanta': true,
      },
      whatsappNumber: '5531997682271',
      updatedAt: DateTime.now(),
    );
  }

  String getWhatsAppUrl([String? customMessage]) {
    final message = Uri.encodeComponent(
      customMessage ?? 'Olá! Gostaria de falar com vocês.',
    );
    return 'https://wa.me/$whatsappNumber?text=$message';
  }
}

// ═══════════════════════════════════════════════════════════
//                    SLOTS CONFIG
// ═══════════════════════════════════════════════════════════
class SlotsConfig {
  final bool enabled;
  final List<String> deliveryWeekday;
  final List<String> deliveryWeekend;
  final List<String> pickupWeekday;
  final List<String> pickupWeekend;
  final Map<String, List<String>> specialDays;
  final List<String> closedDays;

  const SlotsConfig({
    required this.enabled,
    required this.deliveryWeekday,
    required this.deliveryWeekend,
    required this.pickupWeekday,
    required this.pickupWeekend,
    required this.specialDays,
    required this.closedDays,
  });

  factory SlotsConfig.fromJson(Map<String, dynamic> json) {
    return SlotsConfig(
      enabled: json['enabled'] ?? true,
      
      // Listas simples geralmente não dão erro com null safety se usarmos o ?? []
      deliveryWeekday: List<String>.from(json['delivery_weekday'] ?? [
        '09:00 - 12:00',
        '12:00 - 15:00',
        '15:00 - 18:00',
        '18:00 - 20:00',
      ]),
      deliveryWeekend: List<String>.from(json['delivery_weekend'] ?? [
        '09:00 - 12:00',
        '12:00 - 15:00',
        '15:00 - 16:00',
      ]),
      pickupWeekday: List<String>.from(json['pickup_weekday'] ?? [
        '09:00 - 12:00',
        '12:00 - 15:00',
        '15:00 - 18:00',
      ]),
      pickupWeekend: List<String>.from(json['pickup_weekend'] ?? [
        '09:00 - 12:00',
      ]),

      // ✅ CORREÇÃO 3 (A MAIS IMPORTANTE): special_days
      // Se o PHP mandar [] (array vazio), o 'is Map' falha e retornamos {} (Map vazio)
      specialDays: (json['special_days'] is Map)
          ? (json['special_days'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            )
          : {},
      
      closedDays: List<String>.from(json['closed_days'] ?? []),
    );
  }

  factory SlotsConfig.defaultConfig() {
    return const SlotsConfig(
      enabled: true,
      deliveryWeekday: [
        '09:00 - 12:00',
        '12:00 - 15:00',
        '15:00 - 18:00',
        '18:00 - 20:00',
      ],
      deliveryWeekend: [
        '09:00 - 12:00',
        '12:00 - 15:00',
        '15:00 - 16:00',
      ],
      pickupWeekday: [
        '09:00 - 12:00',
        '12:00 - 15:00',
        '15:00 - 18:00',
      ],
      pickupWeekend: [
        '09:00 - 12:00',
      ],
      specialDays: {},
      closedDays: [],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//                    CUSTOM MESSAGE
// ═══════════════════════════════════════════════════════════
class CustomMessage {
  final bool enabled;
  final String title;
  final String message;
  final String type;

  const CustomMessage({
    required this.enabled,
    required this.title,
    required this.message,
    required this.type,
  });

  factory CustomMessage.fromJson(Map<String, dynamic> json) {
    return CustomMessage(
      enabled: json['enabled'] ?? false,
      title: json['title'] ?? 'Atenção!',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
    );
  }

  factory CustomMessage.defaultConfig() {
    return const CustomMessage(
      enabled: false,
      title: 'Atenção!',
      message: '',
      type: 'info',
    );
  }
}

// ═══════════════════════════════════════════════════════════
//                    FEATURES
// ═══════════════════════════════════════════════════════════
class Features {
  final bool enableCheckout;
  final bool enablePixPayment;
  final bool enableCreditCardOnline;
  final bool enableCoupon;
  final int maxItemsPerOrder;

  const Features({
    required this.enableCheckout,
    required this.enablePixPayment,
    required this.enableCreditCardOnline,
    required this.enableCoupon,
    required this.maxItemsPerOrder,
  });

  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      enableCheckout: json['enable_checkout'] ?? true,
      enablePixPayment: json['enable_pix_payment'] ?? true,
      enableCreditCardOnline: json['enable_credit_card_online'] ?? false,
      enableCoupon: json['enable_coupon'] ?? true,
      maxItemsPerOrder: json['max_items_per_order'] ?? 50,
    );
  }

  factory Features.defaultConfig() {
    return const Features(
      enableCheckout: true,
      enablePixPayment: true,
      enableCreditCardOnline: false,
      enableCoupon: true,
      maxItemsPerOrder: 50,
    );
  }
}