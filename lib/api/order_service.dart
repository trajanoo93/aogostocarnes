

import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  // Substitua pelas chaves reais do WooCommerce (NÃO comita no git por segurança; use env ou secrets).
  // Para produção, considere um proxy backend para ocultar as chaves.
  static const String consumerKey = 'ck_5156e2360f442f2585c8c9a761ef084b710e811f';
  static const String consumerSecret = 'cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c';

  final String _baseUrl = 'https://aogosto.com.br/delivery/wp-json/wc/v3/orders';

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final uri = Uri.parse(_baseUrl);
    final basicAuth = 'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': basicAuth,
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao criar pedido: ${response.statusCode} - ${response.body}');
    }
  }
}