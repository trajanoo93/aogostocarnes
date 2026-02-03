// lib/api/product_service.dart - VERSÃO DEFINITIVA COM CACHE INTELIGENTE

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/models/product_variation.dart';

class ProductService {
  final String _baseUrl = 'https://aogosto.com.br/delivery/wp-json/wc/v3';
  final String _consumerKey = 'ck_5156e2360f442f2585c8c9a761ef084b710e811f';
  final String _consumerSecret = 'cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c';

  static const _placeholder =
      'https://aogosto.com.br/delivery/wp-content/uploads/2023/12/Go-Express-fundo-400-x-200-px2-1.png';

  String get _authHeader {
    final credentials = base64Encode(
      utf8.encode('$_consumerKey:$_consumerSecret'),
    );
    return 'Basic $credentials';
  }

  // ==============================================================================
  // 🛡️ VALIDAÇÃO DE ESTOQUE EM TEMPO REAL (SEM CACHE)
  // ==============================================================================
  Future<List<String>> validateStock(List<dynamic> cartItems) async {
    final List<String> outOfStockItems = [];

    for (final item in cartItems) {
      try {
        final productId = item.product.id;
        final variationId = item.variationId;
        final quantity = item.quantity;

        String url;
        if (variationId != null && variationId > 0) {
          // Checa a variação específica
          url = '$_baseUrl/products/$productId/variations/$variationId';
        } else {
          // Checa o produto simples
          url = '$_baseUrl/products/$productId';
        }

        final resp = await http.get(
          Uri.parse(url),
          headers: {'Authorization': _authHeader},
        );

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          
          final stockStatus = data['stock_status']; // 'instock', 'outofstock', 'onbackorder'
          final manageStock = data['manage_stock'] == true;
          final stockQty = data['stock_quantity']; // pode ser null

          // 1. Verifica status geral
          if (stockStatus != 'instock') {
            outOfStockItems.add("${item.product.name} (Esgotado)");
            continue;
          }

          // 2. Verifica quantidade numérica (se gerenciamento estiver ativo)
          if (manageStock && stockQty != null) {
            if (stockQty < quantity) {
              outOfStockItems.add("${item.product.name} (Apenas $stockQty em estoque)");
            }
          }
        } else if (resp.statusCode == 404) {
           outOfStockItems.add("${item.product.name} (Não encontrado)");
        }
      } catch (e) {
        print('Erro ao validar estoque do item ${item.product.name}: $e');
        // Em caso de erro de rede, optamos por não bloquear, ou bloquear dependendo da regra de negócio.
        // Aqui não adicionamos à lista para não travar venda por erro de internet momentâneo.
      }
    }

    return outOfStockItems;
  }

  // ✨ CACHE EM MEMÓRIA COM EXPIRAÇÃO CURTA
  static final Map<String, CacheEntry<List<Product>>> _cache = {};
  static final Map<int, Product> _productCache = {};
  
  // ⏰ Cache de apenas 2 minutos (atualização rápida de preços)
  static const Duration _cacheDuration = Duration(minutes: 2);

  static const String _FIELDS =
      'id,name,type,regular_price,sale_price,price,images,short_description,categories,meta_data,attributes,variations';

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '.');
    return double.tryParse(s);
  }

  bool _toBool(dynamic v) {
    final s = v?.toString().toLowerCase();
    return s == 'yes' || s == 'true' || s == '1';
  }

  dynamic _findMeta(List<dynamic>? meta, String key) {
    if (meta == null) return null;
    for (final m in meta) {
      if (m is Map && m['key'] == key) return m['value'];
    }
    return null;
  }

  Future<Product?> fetchProductById(int productId) async {
    if (_productCache.containsKey(productId)) {
      return _productCache[productId];
    }

    final url = '$_baseUrl/products/$productId?_fields=$_FIELDS';
    try {
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final product = _mapProduct(data);
        _productCache[productId] = product;
        return product;
      }
    } catch (e) {
      print('Erro ao carregar produto $productId: $e');
    }
    return null;
  }

  Product _mapProduct(Map<String, dynamic> p) {
    final meta = (p['meta_data'] as List?)?.cast<Map<String, dynamic>>();
    final catIds = ((p['categories'] as List?) ?? [])
        .map((c) => (c is Map && c['id'] is int) ? c['id'] as int? : null)
        .whereType<int>()
        .toList();

    String type = (p['type'] ?? 'simple').toString();

    List<ProductAttribute>? attributes;
    if (type == "variable") {
      final attrsRaw = (p['attributes'] as List?) ?? [];
      attributes = attrsRaw
          .where((a) => a['variation'] == true)
          .map((a) => ProductAttribute(
                name: a['name'] ?? '',
                options: (a['options'] as List?)?.cast<String>() ?? const [],
              ))
          .toList();
    }

    final variationIds = (p['variations'] as List?)?.map((v) => v as int).toList();

    final product = Product(
      id: (p['id'] as num).toInt(),
      name: (p['name'] as String?) ?? '',
      type: type,
      attributes: attributes,
      variationIds: variationIds,
      price: _toDouble(p['price']) ?? 0.0,
      regularPrice: _toDouble(p['regular_price']),
      imageUrl: (p['images'] as List?)?.isNotEmpty == true
          ? (((p['images'] as List).first)['src'] as String? ?? _placeholder)
          : _placeholder,
      categoryIds: catIds,
      shortDescription: _cleanHtml((p['short_description'] as String?) ?? ''),
      pricePerKg: _toDouble(_findMeta(meta, '_price_per_kg')),
      averageWeightGrams: _toDouble(_findMeta(meta, '_weight_grams')),
      isFrozen: _toBool(_findMeta(meta, '_is_frozen')),
      isChilled: _toBool(_findMeta(meta, '_is_chilled')),
      isSeasoned: _toBool(_findMeta(meta, '_is_seasoned')),
      isBestseller: _toBool(_findMeta(meta, '_is_bestseller')),
    );

    _productCache[product.id] = product;

    return product;
  }

  String _cleanHtml(String input) {
    if (input.trim().isEmpty) return '';
    var s = input;
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n\n');
    s = s.replaceAll(RegExp(r'</div>\s*<div[^>]*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</div>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n- ');
    s = s.replaceAll(RegExp(r'</li>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll('&nbsp;', ' ');
    s = s.replaceAll('&#8211;', '-');
    s = s.replaceAll('&#8217;', "'");
    s = s.replaceAll('&#8220;', '"');
    s = s.replaceAll('&#8221;', '"');
    s = s.replaceAll('&amp;', '&');
    s = s.replaceAll('&quot;', '"');
    s = s.replaceAll('&lt;', '<');
    s = s.replaceAll('&gt;', '>');
    s = s.replaceAll(RegExp(r'&#\d+;'), '');
    s = s.replaceAll(RegExp(r'&[a-z]+;', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r' +'), ' ');
    s = s.replaceAll(RegExp(r'\t+'), '');
    s = s.replaceAll(RegExp(r' *\n *'), '\n');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    final lines = s.split('\n').map((line) => line.trim()).where((line) {
      if (line.isEmpty) return false;
      final upper = line.toUpperCase();
      return !upper.contains('IMAGEM') &&
             !upper.contains('ILUSTRATIVA') &&
             !upper.contains('MERAMENTE') &&
             !upper.startsWith('*') &&
             !upper.contains('***');
    }).toList();

    return lines.join('\n').trim();
  }

  Future<List<ProductVariation>> fetchProductVariations(int productId) async {
    final url = '$_baseUrl/products/$productId/variations?per_page=100';
    
    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {'Authorization': _authHeader},
      );
      
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        return data
            .map((e) => ProductVariation.fromWoo(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('❌ Erro ao buscar variações do produto $productId: $e');
    }
    
    return [];
  }

  // ✨ OFERTAS (COM CACHE + FORCE REFRESH)
  Future<List<Product>> fetchOnSaleProducts({int perPage = 20, bool forceRefresh = false}) async {
    final cacheKey = 'onsale_$perPage';
    
    if (!forceRefresh && _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      print('✅ Cache HIT: Ofertas');
      return _cache[cacheKey]!.data;
    }

    print('🔄 Buscando ofertas...');
    
    final url = '$_baseUrl/products?status=publish&per_page=$perPage&stock_status=instock&category=72&_fields=$_FIELDS';
    try {
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        final products = data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
        
        _cache[cacheKey] = CacheEntry(products, DateTime.now().add(_cacheDuration));
        
        return products;
      }
    } catch (e) {
      print('❌ Erro ao buscar ofertas: $e');
    }
    return [];
  }

  Future<List<Product>> fetchProductsBySearch(String query) async {
    final cacheKey = 'search_$query';
    
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      print('✅ Cache HIT: Busca "$query"');
      return _cache[cacheKey]!.data;
    }

    final url = '$_baseUrl/products?search=${Uri.encodeComponent(query)}&per_page=30&status=publish&stock_status=instock&_fields=$_FIELDS';
    try {
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        final products = data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
        
        _cache[cacheKey] = CacheEntry(products, DateTime.now().add(_cacheDuration));
        
        return products;
      }
    } catch (_) {}
    return [];
  }

  Future<List<Product>> fetchProductsByCategory(
    int categoryId, {
    int perPage = 20,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'cat_${categoryId}_${perPage}_$page';
    
    if (!forceRefresh && _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      print('✅ Cache HIT: Categoria $categoryId');
      return _cache[cacheKey]!.data;
    }

    print('🔄 Buscando categoria $categoryId...');

    final url = '$_baseUrl/products?'
        'status=publish'
        '&per_page=$perPage'
        '&page=$page'
        '&stock_status=instock'
        '&category=$categoryId'
        '&_fields=$_FIELDS';

    try {
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        final products = data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
        
        _cache[cacheKey] = CacheEntry(products, DateTime.now().add(_cacheDuration));
        
        return products;
      }
    } catch (e) {
      print('Erro ao carregar categoria $categoryId: $e');
    }
    return [];
  }

  Future<List<Product>> fetchProductsByCategories(
    List<int> categoryIds, {
    int perCategory = 20,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (categoryIds.isEmpty) return [];

    final cacheKey = 'cats_${categoryIds.join('_')}_${perCategory}_$page';
    
    if (!forceRefresh && _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      print('✅ Cache HIT: Categorias múltiplas');
      return _cache[cacheKey]!.data;
    }

    print('🔄 Buscando categorias múltiplas...');

    try {
      final futures = categoryIds.map((id) {
        final url =
            '$_baseUrl/products?status=publish&per_page=$perCategory&page=$page&stock_status=instock&category=$id&_fields=$_FIELDS';
        return http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      }).toList();

      final responses = await Future.wait(futures);
      final Map<int, Product> unique = {};

      for (final resp in responses) {
        if (resp.statusCode == 200) {
          final List data = json.decode(resp.body);
          for (final item in data) {
            final p = _mapProduct(item);
            unique[p.id] = p;
          }
        }
      }
      
      final products = unique.values.toList();
      _cache[cacheKey] = CacheEntry(products, DateTime.now().add(_cacheDuration));
      
      return products;
    } catch (_) {
      return [];
    }
  }

  // ✨ LIMPAR CACHE (para pull-to-refresh)
  static void clearCache() {
    _cache.clear();
    _productCache.clear();
    print('🗑️ Cache limpo!');
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}