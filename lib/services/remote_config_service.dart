// lib/services/remote_config_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static const String _configUrl = 'https://aogosto.com.br/app/oms/api.php';
  static const String _cacheKey = 'remote_config_cache';
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  static RemoteConfig? _cachedConfig;
  static DateTime? _lastFetch;
  
  /// Busca configurações remotas (com cache)
  static Future<RemoteConfig> fetchConfig({bool forceRefresh = false}) async {
    // Retorna cache se ainda válido
    if (!forceRefresh && _cachedConfig != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _cacheDuration) {
        return _cachedConfig!;
      }
    }
    
    try {
      final response = await http.get(
        Uri.parse(_configUrl),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final config = RemoteConfig.fromJson(data);
        
        // Salva no cache
        _cachedConfig = config;
        _lastFetch = DateTime.now();
        
        // Persiste localmente
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_cacheKey, response.body);
        
        return config;
      } else {
        return _loadFromCache();
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar config remota: $e');
      return _loadFromCache();
    }
  }
  
  /// Carrega do cache local (fallback)
  static Future<RemoteConfig> _loadFromCache() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final cached = sp.getString(_cacheKey);
      
      if (cached != null) {
        return RemoteConfig.fromJson(json.decode(cached));
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar cache: $e');
    }
    
    // Retorna config padrão como último recurso
    return RemoteConfig.defaultConfig();
  }
}

/// Modelo de configuração remota
class RemoteConfig {
  final bool appEnabled;
  final String maintenanceMessage;
  final bool showChristmasCarousel;
  final SlotsConfig slotsConfig;
  final CustomMessage customMessage;
  final Features features;
  final Map<String, bool> pickupStores;
  final DateTime updatedAt;
  
  RemoteConfig({
    required this.appEnabled,
    required this.maintenanceMessage,
    required this.showChristmasCarousel,
    required this.slotsConfig,
    required this.customMessage,
    required this.features,
    required this.pickupStores,
    required this.updatedAt,
  });
  
 factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      appEnabled: json['app_enabled'] ?? true,
      maintenanceMessage: json['maintenance_message'] ?? 'Estamos em manutenção!',
      showChristmasCarousel: json['show_christmas_carousel'] ?? false,
      slotsConfig: SlotsConfig.fromJson(json['slots_config'] ?? {}),
      customMessage: CustomMessage.fromJson(json['custom_message'] ?? {}),
      features: Features.fromJson(json['features'] ?? {}),
      // ✅ NOVO: Pickup Stores
      pickupStores: (json['pickup_stores'] as Map<String, dynamic>? ?? {
        'barreiro': true,
        'sion': true,
        'central': true,
        'lagosanta': true,
      }).map((k, v) => MapEntry(k, v as bool)),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
  
  factory RemoteConfig.defaultConfig() {
    return RemoteConfig(
      appEnabled: true,
      maintenanceMessage: 'Estamos em manutenção!',
      showChristmasCarousel: false,
      slotsConfig: SlotsConfig.defaultConfig(),
      customMessage: CustomMessage.defaultConfig(),
      features: Features.defaultConfig(),
      pickupStores: {  // ← ✅ NOVO
        'barreiro': true,
        'sion': true,
        'central': true,
        'lagosanta': true,
      },
      updatedAt: DateTime.now(),
    );
  }
}

class SlotsConfig {
  final bool enabled;
  final List<String> deliveryWeekday;
  final List<String> deliveryWeekend;
  final List<String> pickupWeekday;
  final List<String> pickupWeekend;
  final Map<String, List<String>> specialDays;
  final List<String> closedDays;
  
  SlotsConfig({
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
      deliveryWeekday: List<String>.from(json['delivery_weekday'] ?? []),
      deliveryWeekend: List<String>.from(json['delivery_weekend'] ?? []),
      pickupWeekday: List<String>.from(json['pickup_weekday'] ?? []),
      pickupWeekend: List<String>.from(json['pickup_weekend'] ?? []),
      specialDays: (json['special_days'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ),
      closedDays: List<String>.from(json['closed_days'] ?? []),
    );
  }
  
  factory SlotsConfig.defaultConfig() {
    return SlotsConfig(
      enabled: true,
      deliveryWeekday: ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00', '18:00 - 20:00'],
      deliveryWeekend: ['09:00 - 12:00'],
      pickupWeekday: ['09:00 - 12:00', '12:00 - 15:00', '15:00 - 18:00'],
      pickupWeekend: ['09:00 - 12:00'],
      specialDays: {},
      closedDays: [],
    );
  }
}

class CustomMessage {
  final bool enabled;
  final String title;
  final String message;
  final String type;
  
  CustomMessage({
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
    return CustomMessage(
      enabled: false,
      title: 'Atenção!',
      message: '',
      type: 'info',
    );
  }
}

class Features {
  final bool enableCheckout;
  final bool enablePixPayment;
  final bool enableCreditCardOnline; 
  final bool enableCoupon;
  final int maxItemsPerOrder;
  
  Features({
    required this.enableCheckout,
    required this.enablePixPayment,
    required this.enableCoupon,
    required this.enableCreditCardOnline,
    required this.maxItemsPerOrder,
  });
  
  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      enableCheckout: json['enable_checkout'] ?? true,
      enablePixPayment: json['enable_pix_payment'] ?? true,
      enableCreditCardOnline: json['enable_credit_card_online'] ?? false,  // ← ✅ NOVO
      enableCoupon: json['enable_coupon'] ?? true,
      maxItemsPerOrder: json['max_items_per_order'] ?? 50,
    );
  }
  
  factory Features.defaultConfig() {
    return Features(
      enableCheckout: true,
      enablePixPayment: true,
      enableCreditCardOnline: false,  // ← ✅ NOVO
      enableCoupon: true,
      maxItemsPerOrder: 50,
    );
  }
}