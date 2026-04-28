import 'dart:convert';
import 'dart:io';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/AdminOrder.dart';
import 'package:ecommerce_flutter/src/domain/models/AttributeType.dart';
import 'package:ecommerce_flutter/src/domain/models/MitaiProduct.dart';
import 'package:ecommerce_flutter/src/domain/models/ProductVariant.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

class MitaiApiService {
  // Host is read at call time from TenantSession — supports runtime tenant switching.
  String get _baseHost => TenantSession.host;

  String? get _token {
    final t = SecureStorageService.authToken;
    return t.isEmpty ? null : t;
  }

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    final token = _token;
    if (token != null) h['Authorization'] = 'Bearer $token';
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) h['X-App-Token'] = appToken;
    return h;
  }

  Map<String, String> get _authHeaders {
    final h = <String, String>{'Accept': 'application/json'};
    final token = _token;
    if (token != null) h['Authorization'] = 'Bearer $token';
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) h['X-App-Token'] = appToken;
    return h;
  }

  String _parseError(http.Response response, String fallback) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return '$fallback (HTTP ${response.statusCode})';
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Resource<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final url = Uri.https(_baseHost, '/api/login');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final appToken = TenantSession.appToken;
      if (appToken != null && appToken.isNotEmpty) headers['X-App-Token'] = appToken;
      final response = await http.post(url,
          headers: headers,
          body: json.encode({'email': email, 'password': password}));
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) return Success(data);
      return Error(data['message']?.toString() ?? 'Login error');
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Catalog (read) ───────────────────────────────────────────────────────

  Future<Resource<Map<String, dynamic>>> getHomeAdmin() async {
    try {
      final url = Uri.https(_baseHost, '/api/home/admin/${TenantSession.host.split(".").first}');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(json.decode(response.body) as Map<String, dynamic>);
      }
      return Error(_parseError(response, 'Error al cargar el catálogo'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<dynamic>>> getCategoriesByDepartment(int deptId) async {
    try {
      final url = Uri.https(_baseHost, '/api/categories/by-department/$deptId/${TenantSession.host.split(".").first}');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(data['data'] as List<dynamic>? ?? []);
      }
      return Error(_parseError(response, 'Error al cargar categorías'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Map<String, dynamic>>> getProductsByCategoryPaged(
    int categoryId, {
    int page = 1,
    int perPage = 15,
    String status = '1',
    String search = '',
  }) async {
    try {
      final params = <String, String>{
        'status': status,
        'page': '$page',
        'per_page': '$perPage',
      };
      if (search.isNotEmpty) params['search'] = search;
      final url = Uri.https(_baseHost, '/api/products/category/$categoryId/${TenantSession.host.split(".").first}', params);
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(json.decode(response.body) as Map<String, dynamic>);
      }
      return Error(_parseError(response, 'Error al cargar productos'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<MitaiProduct>>> getProductsByCategory(int categoryId) async {
    try {
      final url = Uri.https(_baseHost, '/api/products/category/$categoryId/${TenantSession.host.split(".").first}',
          {'status': '1', 'per_page': '200'});
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(MitaiProduct.fromJsonList(data['data'] as List<dynamic>? ?? []));
      }
      return Error(_parseError(response, 'Error al cargar productos'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<ProductVariant>>> getProductVariants(int productId) async {
    try {
      final url = Uri.https(_baseHost, '/api/products/$productId/variants/${TenantSession.host.split(".").first}');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(ProductVariant.fromJsonList(data['data'] as List<dynamic>? ?? []));
      }
      return Error(_parseError(response, 'Error al cargar variantes'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Admin CRUD ───────────────────────────────────────────────────────────

  Future<Resource<Map<String, dynamic>>> getProductForEdit(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/product/$id');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(json.decode(response.body) as Map<String, dynamic>);
      }
      return Error(_parseError(response, 'Error al cargar producto'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Map<String, dynamic>>> createProduct({
    required String name,
    required String code,
    required String description,
    required double price,
    required int stock,
    required bool manageStock,
    required bool trending,
    required double? discount,
    required String? metaKeywords,
    required List<int> categoryIds,
    required List<Map<String, dynamic>> combos,
    required List<File> images,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.https(_baseHost, '/api/admin/products'));
      _authHeaders.forEach((k, v) => request.headers[k] = v);

      request.fields['name']         = name;
      request.fields['code']         = code;
      request.fields['description']  = description;
      request.fields['price']        = price.toString();
      request.fields['stock']        = stock.toString();
      request.fields['manage_stock'] = manageStock ? '1' : '0';
      request.fields['trending']     = trending ? '1' : '0';
      if (discount != null && discount > 0) request.fields['discount'] = discount.toString();
      if (metaKeywords != null) request.fields['meta_keywords'] = metaKeywords;
      request.fields['category_ids'] = json.encode(categoryIds);
      request.fields['combos']       = json.encode(combos);

      for (final file in images) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) return Success(data);
      return Error(data['message']?.toString() ?? 'Error al crear producto');
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Map<String, dynamic>>> updateProduct({
    required int id,
    required String name,
    required String code,
    required String description,
    required double price,
    required int stock,
    required bool manageStock,
    required bool trending,
    required double? discount,
    required String? metaKeywords,
    required List<int> categoryIds,
    required List<Map<String, dynamic>> combos,
    required List<File> newImages,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.https(_baseHost, '/api/admin/products/$id'));
      _authHeaders.forEach((k, v) => request.headers[k] = v);

      request.fields['name']         = name;
      request.fields['code']         = code;
      request.fields['description']  = description;
      request.fields['price']        = price.toString();
      request.fields['stock']        = stock.toString();
      request.fields['manage_stock'] = manageStock ? '1' : '0';
      request.fields['trending']     = trending ? '1' : '0';
      if (discount != null && discount > 0) request.fields['discount'] = discount.toString();
      if (metaKeywords != null) request.fields['meta_keywords'] = metaKeywords;
      request.fields['category_ids'] = json.encode(categoryIds);
      request.fields['combos']       = json.encode(combos);

      for (final file in newImages) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) return Success(data);
      return Error(data['message']?.toString() ?? 'Error al actualizar producto');
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> deleteProduct(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/products/$id');
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) return Success(true);
      return Error(_parseError(response, 'Error al eliminar producto'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Categories reference ─────────────────────────────────────────────────

  Future<Resource<List<dynamic>>> getAllCategories() async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/categories-all');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(data['data'] as List<dynamic>? ?? []);
      }
      return Error(_parseError(response, 'Error al cargar categorías'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Attributes ───────────────────────────────────────────────────────────

  Future<Resource<List<AttributeType>>> getAllAttributes() async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/attributes-all');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(AttributeType.fromJsonList(data['data'] as List<dynamic>? ?? []));
      }
      return Error(_parseError(response, 'Error al cargar atributos'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<AttributeType>> createAttribute(String name) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/attributes');
      final response = await http.post(url,
          headers: _headers, body: json.encode({'name': name}));
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(AttributeType.fromJson(data['data']));
      }
      return Error(data['message']?.toString() ?? 'Error');
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<AttributeValue>> createAttributeValue(int attrId, String value) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/attributes/$attrId/values');
      final response = await http.post(url,
          headers: _headers, body: json.encode({'value': value}));
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(AttributeValue.fromJson(data['data']));
      }
      return Error(data['message']?.toString() ?? 'Error');
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> deleteAttribute(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/attributes/$id');
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) return Success(true);
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> deleteAttributeValue(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/attribute-values/$id');
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) return Success(true);
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  // ─── Orders API ───────────────────────────────────────────────────────────

  Future<Resource<Map<String, dynamic>>> getOrdersPaged({
    int page = 1,
    int perPage = 15,
    String search = '',
    String status = 'all',
    String kind = 'all',
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        'status': status,
        'kind': kind,
      };
      if (search.isNotEmpty) params['search'] = search;
      final url = Uri.https(_baseHost, '/api/admin/orders', params);
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(json.decode(response.body) as Map<String, dynamic>);
      }
      return Error(_parseError(response, 'Error al cargar pedidos'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<AdminOrder>> getOrderDetail(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(AdminOrder.fromJson(data['data'] as Map<String, dynamic>));
      }
      return Error(_parseError(response, 'Error al cargar pedido'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Map<String, dynamic>>> getOrderQuickInfo(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/quick-info');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(json.decode(response.body) as Map<String, dynamic>);
      }
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<int>> toggleOrderApprove(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/approve');
      final response = await http.put(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(data['approved'] as int? ?? 0);
      }
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<int>> toggleOrderDelivery(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/delivery');
      final response = await http.put(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(data['delivered'] as int? ?? 0);
      }
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<int>> toggleOrderReady(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/ready');
      final response = await http.put(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(data['ready_to_give'] as int? ?? 0);
      }
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<int>> updateOrderCancel(int id, int cancel) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/cancel');
      final response = await http.post(url,
          headers: _headers, body: json.encode({'cancel': cancel}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(data['cancel_buy'] as int? ?? cancel);
      }
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<String>> updateOrderGuideNumber(int id, String guideNumber) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/guide-number');
      final response = await http.post(url,
          headers: _headers, body: json.encode({'guide_number': guideNumber}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success(data['guide_number']?.toString() ?? guideNumber);
      }
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> updateOrderNote(int id, String note) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/note');
      final response = await http.post(url,
          headers: _headers, body: json.encode({'detail': note}));
      if (response.statusCode == 200 || response.statusCode == 201) return Success(true);
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<double>> addOrderAbono(int id, double monto) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id/abono');
      final response = await http.post(url,
          headers: _headers, body: json.encode({'monto': monto}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Success((data['monto_apartado'] as num?)?.toDouble() ?? 0.0);
      }
      return Error(_parseError(response, 'Error'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> deleteOrder(int id) async {
    try {
      final url = Uri.https(_baseHost, '/api/admin/orders/$id');
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 201) return Success(true);
      return Error(_parseError(response, 'Error al eliminar pedido'));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
