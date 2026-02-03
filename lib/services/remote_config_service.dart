// lib/services/remote_config_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  // Adicionamos um parâmetro de tempo na URL para evitar cache agressivo do servidor/CDN
  static const String _baseUrl = 'https://aogosto.com.br/app/oms/api.php';
  static const String _cacheKey = 'remote_config_cache';
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  static RemoteConfig? _cachedConfig;
  static DateTime? _lastFetch;

  static Future<RemoteConfig> fetchConfig({bool forceRefresh = false}) async {
    try {
      // 1. Verifica Cache de Memória (para navegação rápida dentro do app)
      if (!forceRefresh && _cachedConfig != null && _lastFetch != null) {
        final now = DateTime.now();
        if (now.difference(_lastFetch!) < _cacheDuration) {
          debugPrint('🔵 [RemoteConfig] Usando cache de memória (Válido)');
          return _cachedConfig!;
        }
      }

      // 2. Busca na API (com timestamp para garantir dados frescos)
      final uri = Uri.parse('$_baseUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      debugPrint('🔵 [RemoteConfig] Buscando: $uri');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      debugPrint('📡 [RemoteConfig] Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Log do corpo para debug (verifique isso no terminal se der erro)
        debugPrint('📡 [RemoteConfig] Body: ${response.body}');
        
        final jsonData = json.decode(response.body);
        
        // Parsing Seguro (Blinda contra tipos errados do PHP)
        final config = RemoteConfig.fromJson(jsonData);
        
        // Atualiza Cache
        _cachedConfig = config;
        _lastFetch = DateTime.now();
        
        // Persiste no disco
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_cacheKey, response.body);
        
        debugPrint('✅ [RemoteConfig] Carregado com sucesso!');
        return config;
      } else {
        debugPrint('⚠️ [RemoteConfig] Erro na API. Status: ${response.statusCode}');
        return _loadFromCache();
      }
    } catch (e) {
      debugPrint('❌ [RemoteConfig] Exception ao buscar: $e');
      return _loadFromCache();
    }
  }

  static Future<RemoteConfig> _loadFromCache() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final cachedJson = sp.getString(_cacheKey);
      
      if (cachedJson != null) {
        debugPrint('📦 [RemoteConfig] Recuperando do Cache Local (Disco)');
        return RemoteConfig.fromJson(json.decode(cachedJson));
      }
    } catch (e) {
      debugPrint('⚠️ [RemoteConfig] Falha ao ler cache local: $e');
    }
    
    debugPrint('🔴 [RemoteConfig] Usando Default Config (Fallback Total)');
    return RemoteConfig.defaultConfig();
  }
}

// ═══════════════════════════════════════════════════════════
//                    MODELO REMOTE CONFIG (BLINDADO)
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

  /// 🛡️ MÁGICA: Converte qualquer coisa (0, 1, "true", "0") em bool seguro.
  /// Isso resolve o problema de travamento se o PHP mandar "0" ou 0.
  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final v = value.toLowerCase();
      return v == '1' || v == 'true' || v == 'yes' || v == 'on';
    }
    return defaultValue;
  }

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      // ✅ Default true para o app não travar se o campo vier nulo
      appEnabled: _parseBool(json['app_enabled'], defaultValue: true),
      
      maintenanceMessage: json['maintenance_message'] ?? 'Estamos em manutenção.',
      
      showChristmasCarousel: _parseBool(json['show_christmas_carousel']),
      
      // ✅ Proteção: Se slots_config não for Map, usa default
      slotsConfig: (json['slots_config'] is Map<String, dynamic>)
          ? SlotsConfig.fromJson(json['slots_config'])
          : SlotsConfig.defaultConfig(),

      customMessage: CustomMessage.fromJson(json['custom_message'] ?? {}),
      
      features: Features.fromJson(json['features'] ?? {}),
      
      // ✅ Proteção: Se pickup_stores não for Map, usa default
      pickupStores: (json['pickup_stores'] is Map)
          ? Map<String, bool>.from(json['pickup_stores'])
          : {
              'barreiro': true,
              'sion': true,
              'central': true,
              'lagosanta': true,
            },
      
      whatsappNumber: json['whatsapp_number'] ?? '553122980807',
      
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory RemoteConfig.defaultConfig() {
    return RemoteConfig(
      appEnabled: true, // Padrão ABERTO
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
      // ✅ Atualizado para o número novo
      whatsappNumber: '553122980807',
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
      enabled: RemoteConfig._parseBool(json['enabled'], defaultValue: true),
      
      deliveryWeekday: List<String>.from(json['delivery_weekday'] ?? [
        '09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00', '18:00 - 20:00'
      ]),
      
      deliveryWeekend: List<String>.from(json['delivery_weekend'] ?? [
        '09:00 - 12:00', '12:00 - 15:00', '15:00 - 16:00'
      ]),
      
      pickupWeekday: List<String>.from(json['pickup_weekday'] ?? [
        '09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00'
      ]),
      
      pickupWeekend: List<String>.from(json['pickup_weekend'] ?? [
        '09:00 - 12:00'
      ]),

      // ✅ Proteção crítica: PHP envia array vazio [] quando map está vazio.
      // O Dart espera Map. Essa lógica previne o crash.
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
        '09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00', '18:00 - 20:00'
      ],
      deliveryWeekend: [
        '09:00 - 12:00', '12:00 - 15:00', '15:00 - 16:00'
      ],
      pickupWeekday: [
        '09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00'
      ],
      pickupWeekend: [
        '09:00 - 12:00'
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
  final String type; // info, warning, error, success

  const CustomMessage({
    required this.enabled,
    required this.title,
    required this.message,
    required this.type,
  });

  factory CustomMessage.fromJson(Map<String, dynamic> json) {
    return CustomMessage(
      enabled: RemoteConfig._parseBool(json['enabled']),
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
      enableCheckout: RemoteConfig._parseBool(json['enable_checkout'], defaultValue: true),
      enablePixPayment: RemoteConfig._parseBool(json['enable_pix_payment'], defaultValue: true),
      enableCreditCardOnline: RemoteConfig._parseBool(json['enable_credit_card_online']),
      enableCoupon: RemoteConfig._parseBool(json['enable_coupon'], defaultValue: true),
      maxItemsPerOrder: int.tryParse(json['max_items_per_order']?.toString() ?? '50') ?? 50,
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