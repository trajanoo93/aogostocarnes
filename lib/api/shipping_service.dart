// api/shipping_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço para calcular taxa de entrega pelo CEP (endpoint Woo custom).
class ShippingService {
  final String _endpointBase =
      'https://aogosto.com.br/delivery/wp-json/custom/v1/shipping-cost?cep=';

  Future<double> fetchDeliveryFee(String cep) async {
    if (cep.isEmpty) return 0.0;
    try {
      final url = Uri.parse('$_endpointBase${cep.replaceAll(RegExp(r'[^0-9]'), '')}');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
        final options = (jsonBody['shipping_options'] as List?) ?? const [];
        if (options.isNotEmpty && options.first is Map) {
          final costStr = (options.first as Map)['cost']?.toString();
          if (costStr != null) {
            final parsed = double.tryParse(costStr.replaceAll(',', '.')) ?? 0.0;
            return parsed;
          }
        }
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
