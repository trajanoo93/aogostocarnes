// lib/api/shipping_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Informações da loja e frete retornadas pelo endpoint
class StoreInfo {
  final String name;     // "Unidade Barreiro"
  final String id;       // "110727"
  final double cost;     // 19.90

  const StoreInfo({
    required this.name,
    required this.id,
    required this.cost,
  });
}

/// Serviço para calcular taxa de entrega pelo CEP
class ShippingService {
  final String _endpointBase =
      'https://aogosto.com.br/delivery/wp-json/custom/v1/shipping-cost?cep=';

  /// Retorna [StoreInfo] com nome, ID e custo do frete
  /// 
  /// ✅ NOVO: Validações de segurança:
  /// - Se API falhar → Retorna fallback R$ 20,00
  /// - Se taxa < R$ 9,90 → Retorna fallback R$ 20,00
  /// - Se CEP fora de área → Retorna null (bloqueia checkout)
  Future<StoreInfo?> fetchDeliveryFee(
    String cep, {
    String? deliveryDate,  // Novo: YYYY-MM-DD opcional
    String? deliveryTime,  // Novo: "18:00-20:00" opcional
  }) async {
    if (cep.isEmpty) {
      print('⚠️ CEP vazio fornecido');
      return null;
    }

    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanCep.length != 8) {
        print('⚠️ CEP inválido (deve ter 8 dígitos): $cleanCep');
        return null;
      }
      
      String url = '$_endpointBase$cleanCep';
      
      // Adiciona params opcionais
      if (deliveryDate != null && deliveryDate.isNotEmpty) {
        url += '&delivery_date=$deliveryDate';
      }
      if (deliveryTime != null && deliveryTime.isNotEmpty) {
        url += '&delivery_time=$deliveryTime';
      }

      print('🔍 Buscando frete: $url');

      final uri = Uri.parse(url);
      final resp = await http.get(
        uri, 
        headers: {'Accept': 'application/json'}
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        print('❌ API retornou status ${resp.statusCode}');
        print('📄 Resposta: ${resp.body}');
        return _getFallbackFee();
      }

      final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
      final options = (jsonBody['shipping_options'] as List?) ?? [];

      if (options.isEmpty) {
        print('❌ CEP fora de área: nenhuma opção de frete retornada');
        return null; // ✅ Retorna null para bloquear checkout
      }
      
      if (options.first is! Map) {
        print('❌ Formato inválido da resposta da API');
        return _getFallbackFee();
      }

      final option = options.first as Map<String, dynamic>;
      final costStr = option['cost']?.toString();
      final storeName = option['store']?.toString() ?? 'Central Distribuição';
      final storeId = option['store_id']?.toString() ?? '86261';

      final cost = double.tryParse(costStr?.replaceAll(',', '.') ?? '0') ?? 0.0;

      print('✅ Taxa calculada: R\$ $cost - Loja: $storeName (ID: $storeId)');

      // ✅ VALIDAÇÃO CRÍTICA: Se API retornar taxa menor que mínima
      if (cost < 9.90) {
        print('⚠️ Taxa menor que mínima (R\$ $cost). Aplicando fallback.');
        return _getFallbackFee();
      }

      return StoreInfo(
        name: storeName,
        id: storeId,
        cost: cost,
      );
    } on http.ClientException catch (e) {
      print('❌ Erro de conexão: $e');
      return _getFallbackFee();
    } on FormatException catch (e) {
      print('❌ Erro ao decodificar JSON: $e');
      return _getFallbackFee();
    } catch (e) {
      print('❌ Erro inesperado no fetchDeliveryFee: $e');
      return _getFallbackFee();
    }
  }

  /// ✅ NOVO: Retorna taxa de segurança quando API falha
  /// Evita pedidos com frete R$ 0,00
  StoreInfo _getFallbackFee() {
    print('🛡️ Aplicando taxa de segurança: R\$ 20,00');
    return const StoreInfo(
      name: 'Central Distribuição (Taxa Padrão)',
      id: '86261',
      cost: 20.00, // Taxa de segurança
    );
  }
}