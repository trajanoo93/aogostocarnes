// lib/api/product_image_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductImageService {
  static const String _baseUrl = 'https://aogosto.com.br/delivery/wp-json/wc/v3';
  static const String _consumerKey = 'ck_5156e2360f442f2585c8c9a761ef084b710e811f';
  static const String _consumerSecret = 'cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c';

  static const _placeholder =
      'https://aogosto.com.br/delivery/wp-content/uploads/2023/12/Go-Express-fundo-400-x-200-px2-1.png';

  String get _authHeader {
    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    return 'Basic $credentials';
  }

  // Cache de imagens em memória para evitar requisições repetidas
  static final Map<String, String> _imageCache = {};

  /// Busca a imagem de um produto pelo nome
  /// Retorna a URL da imagem ou o placeholder se não encontrar
  Future<String> getProductImage(String productName) async {
    // Verifica cache primeiro
    if (_imageCache.containsKey(productName)) {
      return _imageCache[productName]!;
    }

    try {
      // Busca o produto pelo nome
      final searchUrl = '$_baseUrl/products?search=${Uri.encodeComponent(productName)}&per_page=1&_fields=id,images';
      
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {'Authorization': _authHeader},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final product = data.first as Map<String, dynamic>;
          final images = product['images'] as List?;
          
          if (images != null && images.isNotEmpty) {
            final imageUrl = images.first['src'] as String? ?? _placeholder;
            _imageCache[productName] = imageUrl;
            return imageUrl;
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar imagem do produto "$productName": $e');
    }

    // Retorna placeholder se não encontrar
    _imageCache[productName] = _placeholder;
    return _placeholder;
  }

  /// Busca imagens de múltiplos produtos de uma vez
  /// Retorna um mapa com nome do produto como chave e URL da imagem como valor
  Future<Map<String, String>> getMultipleProductImages(List<String> productNames) async {
    final Map<String, String> results = {};
    
    for (final name in productNames) {
      results[name] = await getProductImage(name);
    }
    
    return results;
  }

  /// Limpa o cache de imagens
  static void clearCache() {
    _imageCache.clear();
  }
}