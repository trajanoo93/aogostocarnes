// lib/config/pagarme_credentials.dart
/// Credenciais unificadas do Pagar.me
/// 
/// Como todas as lojas usam a mesma chave, o fator decisivo
/// na conciliação bancária são os METADADOS (store_final)
class PagarMeCredentials {
  // ✅ CREDENCIAL ÚNICA PARA TODAS AS LOJAS
  static const String apiKey = 'sk_2b9fa1c33b224ba19a13ee0880e61d25';
  
  // ✅ DADOS FIXOS DA EMPRESA
  static const String companyName = 'Ao Gosto Carnes Ltda';
  static const String companyEmail = 'financeiro@aogosto.com.br';
  static const String companyCnpj = '06275992000146';
  static const String companyType = 'company';
  
  // ✅ TIMEOUT DO PIX (60 minutos em segundos)
  static const int pixExpiresIn = 3600; // 60 minutos
  
  // ✅ ENDPOINT DO PAGAR.ME
  static const String apiBaseUrl = 'https://api.pagar.me/core/v5/orders';
  
  /// Mapeamento de nomes das lojas (deve ser EXATAMENTE igual ao retornado pelo shipping_service)
  static const Map<String, String> storeNames = {
    '86261': 'Central Distribuição (Sagrada Família)',
    '131813': 'Unidade Lagoa Santa',
    '127163': 'Unidade Sion',
    '110727': 'Unidade Barreiro',
  };
  
  /// Retorna o nome da loja pelo ID
  static String getStoreNameById(String storeId) {
    return storeNames[storeId] ?? 'Central Distribuição (Sagrada Família)';
  }
}