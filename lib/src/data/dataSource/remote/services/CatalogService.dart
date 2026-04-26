import 'dart:convert';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogHomeData.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogNavItem.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

// Public catalog service — no X-App-Token, no auth token.
// Reads from the public /api/catalog/* and existing /api/* endpoints.
class CatalogService {
  String get _host => TenantSession.host;
  String get _tenant => _host.split('.').first;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── Home ────────────────────────────────────────────────────────────────

  Future<Resource<CatalogHomeData>> getHome() async {
    try {
      final url = Uri.https(_host, '/api/catalog/home/$_tenant');
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(CatalogHomeData.fromJson(body));
      }
      return Error(_parseError(res, 'Error al cargar el catálogo'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Products by category (paginated) ────────────────────────────────────

  Future<Resource<Map<String, dynamic>>> getProductsByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 20,
    String search = '',
    List<String> attrValues = const [],
  }) async {
    try {
      final params = <String, String>{
        'status': '1',
        'page': '$page',
        'per_page': '$perPage',
        if (search.isNotEmpty) 'search': search,
        if (attrValues.isNotEmpty) 'attr_values': attrValues.join(','),
      };
      final url = Uri.https(_host, '/api/products/category/$categoryId/$_tenant', params);
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return Success(json.decode(res.body) as Map<String, dynamic>);
      }
      return Error(_parseError(res, 'Error al cargar productos'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Categories by department ─────────────────────────────────────────────

  Future<Resource<List<CatalogNavItem>>> getCategoriesByDepartment(int deptId) async {
    try {
      final url = Uri.https(_host, '/api/categories/by-department/$deptId/$_tenant');
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final list = body['data'] as List<dynamic>? ?? [];
        return Success(CatalogNavItem.fromJsonList(list));
      }
      return Error(_parseError(res, 'Error al cargar categorías'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Product detail ───────────────────────────────────────────────────────

  Future<Resource<Map<String, dynamic>>> getProductDetail(int id) async {
    try {
      final url = Uri.https(_host, '/api/catalog/product/$id/$_tenant');
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return Success(json.decode(res.body) as Map<String, dynamic>);
      }
      return Error(_parseError(res, 'Error al cargar el producto'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Global search (all categories) ─────────────────────────────────────

  Future<Resource<Map<String, dynamic>>> globalSearch(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'page': '$page',
        'per_page': '$perPage',
      };
      final url = Uri.https(_host, '/api/catalog/search/$_tenant', params);
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return Success(json.decode(res.body) as Map<String, dynamic>);
      }
      return Error(_parseError(res, 'Error al buscar productos'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Product variants ─────────────────────────────────────────────────────

  Future<Resource<List<dynamic>>> getProductVariants(int productId) async {
    try {
      final url = Uri.https(_host, '/api/products/$productId/variants/$_tenant');
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(body['data'] as List<dynamic>? ?? []);
      }
      return Error(_parseError(res, 'Error al cargar variantes'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Attributes for filter ────────────────────────────────────────────────

  Future<Resource<List<dynamic>>> getAttributesByCategory(int categoryId) async {
    try {
      final url = Uri.https(_host, '/api/catalog/attributes/$categoryId/$_tenant');
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(body['data'] as List<dynamic>? ?? []);
      }
      return Error(_parseError(res, 'Error al cargar filtros'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  String _parseError(http.Response res, String fallback) {
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
