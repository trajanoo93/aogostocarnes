// lib/api/product_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aogosto_carnes_flutter/models/product.dart';

class ProductService {
  final String _baseUrl = 'https://aogosto.com.br/delivery/wp-json/wc/v3';
  final String _consumerKey = 'ck_5156e2360f442f2585c8c9a761ef084b710e811f';
  final String _consumerSecret = 'cs_c62f9d8f6c08a1d14917e2a6db5dccce2815de8c';

  static const _placeholder =
      'https://aogosto.com.br/delivery/wp-content/uploads/2023/12/Go-Express-fundo-400-x-200-px2-1.png';

  String get _authHeader {
    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    return 'Basic $credentials';
  }

  // Campos retornados do WooCommerce (inclui categorias e meta_data p/ badges)
  static const String _FIELDS =
      'id,name,regular_price,sale_price,price,images,short_description,categories,meta_data';

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

  Product _mapProduct(Map<String, dynamic> p) {
    final meta = (p['meta_data'] as List?)?.cast<Map<String, dynamic>>();
    final catIds = ((p['categories'] as List?) ?? [])
        .map((c) => (c is Map && c['id'] is int) ? c['id'] as int? : null)
        .whereType<int>()
        .toList();

    return Product(
      id: (p['id'] as num).toInt(),
      name: (p['name'] as String?) ?? '',
      price: _toDouble(p['price']) ?? 0.0,
      regularPrice: _toDouble(p['regular_price']),
      imageUrl: (p['images'] as List?)?.isNotEmpty == true
          ? ((((p['images'] as List).first) as Map)['src'] as String? ?? _placeholder)
          : _placeholder,
      categoryIds: catIds,
      shortDescription: (p['short_description'] as String?)?.trim(),
      pricePerKg: _toDouble(_findMeta(meta, '_price_per_kg')),
      averageWeightGrams: _toDouble(_findMeta(meta, '_weight_grams')),
      isFrozen: _toBool(_findMeta(meta, '_is_frozen')),
      isChilled: _toBool(_findMeta(meta, '_is_chilled')),
      isSeasoned: _toBool(_findMeta(meta, '_is_seasoned')),
      isBestseller: _toBool(_findMeta(meta, '_is_bestseller')),
    );
  }

  // -------- Endpoints --------

  /// Ofertas da semana (categoria 72)
  Future<List<Product>> fetchOnSaleProducts({int perPage = 20}) async {
    final url =
        '$_baseUrl/products?status=publish&per_page=$perPage&stock_status=instock&category=72&_fields=$_FIELDS';
    try {
      final resp =
          await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body) as List;
        return data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } catch (_) {
      return [];
    }
  }

  /// Uma categoria (com paginação).
  Future<List<Product>> fetchProductsByCategory(
    int categoryId, {
    int perPage = 20,
    int page = 1,
  }) async {
    final url =
        '$_baseUrl/products?status=publish&per_page=$perPage&page=$page&stock_status=instock&category=$categoryId&_fields=$_FIELDS';
    try {
      final resp =
          await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body) as List;
        return data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } catch (_) {
      return [];
    }
  }

  /// Várias categorias (união). Paginação opcional.
  Future<List<Product>> fetchProductsByCategories(
    List<int> categoryIds, {
    int perCategory = 50,
    int page = 1,
  }) async {
    if (categoryIds.isEmpty) return [];
    final cats = categoryIds.join(',');
    final url =
        '$_baseUrl/products?status=publish&per_page=$perCategory&page=$page&stock_status=instock&category=$cats&_fields=$_FIELDS';

    try {
      final resp =
          await http.get(Uri.parse(url), headers: {'Authorization': _authHeader});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body) as List;
        final items =
            data.map((e) => _mapProduct(e as Map<String, dynamic>)).toList();

        // Dedup por ID (caso o mesmo produto esteja em mais de uma categoria)
        final map = <int, Product>{};
        for (final p in items) {
          map[p.id] = p;
        }
        return map.values.toList();
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } catch (_) {
      return [];
    }
  }
}
