// api/shipping_service.dart
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
  Future<StoreInfo?> fetchDeliveryFee(String cep) async {
    if (cep.isEmpty) return null;

    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      final url = Uri.parse('$_endpointBase$cleanCep');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});

      if (resp.statusCode != 200) return null;

      final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
      final options = (jsonBody['shipping_options'] as List?) ?? [];

      if (options.isEmpty || options.first is! Map) return null;

      final option = options.first as Map<String, dynamic>;
      final costStr = option['cost']?.toString();
      final storeName = option['store']?.toString() ?? 'Central Distribuição';
      final storeId = option['store_id']?.toString() ?? '86261';

      final cost = double.tryParse(costStr?.replaceAll(',', '.') ?? '0') ?? 0.0;

      return StoreInfo(
        name: storeName,
        id: storeId,
        cost: cost,
      );
    } catch (e) {
      print('Erro no fetchDeliveryFee: $e');
      return null;
    }
  }
}