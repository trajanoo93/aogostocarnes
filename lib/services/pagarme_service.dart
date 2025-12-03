// lib/services/pagarme_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ao_gosto_app/config/pagarme_credentials.dart';

/// Resposta do Pagar.me após gerar PIX
class PagarMePixResponse {
  final String qrCodeText;
  final String qrCodeUrl;
  final DateTime expiresAt;
  final String chargeId;
  
  const PagarMePixResponse({
    required this.qrCodeText,
    required this.qrCodeUrl,
    required this.expiresAt,
    required this.chargeId,
  });
  
  factory PagarMePixResponse.fromJson(Map<String, dynamic> json) {
    // O Pagar.me retorna o PIX dentro de charges > last_transaction
    final charges = json['charges'] as List?;
    if (charges == null || charges.isEmpty) {
      throw Exception('Nenhum charge retornado pelo Pagar.me');
    }
    
    final charge = charges.first as Map<String, dynamic>;
    final lastTransaction = charge['last_transaction'] as Map<String, dynamic>?;
    
    if (lastTransaction == null) {
      throw Exception('Nenhuma transação PIX retornada');
    }
    
    final qrCode = lastTransaction['qr_code'] as String? ?? '';
    final qrCodeUrl = lastTransaction['qr_code_url'] as String? ?? '';
    
    // Calcula expiração (60 minutos a partir de agora)
    final expiresAt = DateTime.now().add(
      Duration(seconds: PagarMeCredentials.pixExpiresIn),
    );
    
    return PagarMePixResponse(
      qrCodeText: qrCode,
      qrCodeUrl: qrCodeUrl,
      expiresAt: expiresAt,
      chargeId: charge['id'] as String? ?? '',
    );
  }
}

/// Serviço de integração com Pagar.me
class PagarMeService {
  /// Gera um PIX no Pagar.me
  /// 
  /// [orderId] - ID do pedido no WooCommerce
  /// [storeFinal] - Nome completo da loja (ex: "Unidade Sion")
  /// [totalAmount] - Valor total em REAIS (será convertido para centavos)
  /// [customerPhone] - Telefone do cliente (apenas números)
  Future<PagarMePixResponse> generatePix({
    required String orderId,
    required String storeFinal,
    required double totalAmount,
    required String customerPhone,
  }) async {
    try {
      // ✅ Converte para centavos
      final amountInCents = (totalAmount * 100).round();
      
      // ✅ Formata telefone (remove qualquer não-dígito)
      final phoneDigits = customerPhone.replaceAll(RegExp(r'\D'), '');
      
      // ✅ Valida telefone
      if (phoneDigits.length < 10 || phoneDigits.length > 11) {
        throw Exception('Telefone inválido: $customerPhone');
      }
      
      // ✅ Extrai DDD e número
      final countryCode = '55';
      final areaCode = phoneDigits.substring(0, 2);
      final number = phoneDigits.substring(2);
      
      // ✅ Monta payload do Pagar.me
     final payload = {
        'items': [
          {
            'amount': amountInCents,
            'description': 'Pedido #$orderId - Ao Gosto Carnes',
            'quantity': 1,
            'code': orderId,
          }
        ],
        'customer': {
          'name': PagarMeCredentials.companyName,
          'email': PagarMeCredentials.companyEmail,
          'document': PagarMeCredentials.companyCnpj,
          'type': PagarMeCredentials.companyType,
          'phones': {
            'mobile_phone': {
              'country_code': countryCode,
              'area_code': areaCode,
              'number': number,
            }
          }
        },
        'payments': [
          {
            'payment_method': 'pix',
            'pix': {
              'expires_in': PagarMeCredentials.pixExpiresIn,
            }
          }
        ],
        'metadata': {
          'order_id': orderId,
          'store_final': storeFinal,
          'effective_store_final': storeFinal, // ← AQUI: agora envia os dois campos
        },
        'closed': true,
      };
      
      // ✅ Faz requisição ao Pagar.me
      final response = await http.post(
        Uri.parse(PagarMeCredentials.apiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${_encodeAuth()}',
        },
        body: json.encode(payload),
      );
      
      // ✅ Valida resposta
      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao gerar PIX no Pagar.me: ${response.statusCode}\n${response.body}',
        );
      }
      
      // ✅ Parse da resposta
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      
      return PagarMePixResponse.fromJson(jsonResponse);
    } catch (e) {
      throw Exception('Erro ao gerar PIX: $e');
    }
  }
  
  /// Codifica credenciais em Base64 (Basic Auth)
  String _encodeAuth() {
    final credentials = '${PagarMeCredentials.apiKey}:';
    return base64Encode(utf8.encode(credentials));
  }
}