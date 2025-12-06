// lib/api/product_service.dart - VERSÃO COM SUPORTE A VARIAÇÕES

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
  final url = '$_baseUrl/products/$productId?$_FIELDS';
  try {
    final resp = await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return _mapProduct(data);
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

    return Product(
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

  // ✨ NOVO: BUSCAR VARIAÇÕES DE UM PRODUTO
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

  // OFERTAS
  Future<List<Product>> fetchOnSaleProducts({int perPage = 20}) async {
    final url = '$_baseUrl/products?status=publish&per_page=$perPage&stock_status=instock&category=72&_fields=$_FIELDS';
    try {
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        return data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  // BUSCA
  Future<List<Product>> fetchProductsBySearch(String query) async {
    final url = '$_baseUrl/products?search=${Uri.encodeComponent(query)}&per_page=30&status=publish&stock_status=instock&_fields=$_FIELDS';
    try {
      final resp = await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        return data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Product>> fetchProductsByCategory(
    int categoryId, {
    int perPage = 20,
    int page = 1,
  }) async {
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
        return data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Erro ao carregar categoria $categoryId: $e');
    }
    return [];
  }

  // VÁRIAS CATEGORIAS
  Future<List<Product>> fetchProductsByCategories(
    List<int> categoryIds, {
    int perCategory = 50,
    int page = 1,
  }) async {
    if (categoryIds.isEmpty) return [];

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
      return unique.values.toList();
    } catch (_) {
      return [];
    }
  }
}