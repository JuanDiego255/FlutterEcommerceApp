import 'dart:convert';
import 'dart:io';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class ProductsService {

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': SecureStorageService.authToken,
    };
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) h['X-App-Token'] = appToken;
    return h;
  }

  void _applyHeaders(http.MultipartRequest request) {
    request.headers['Authorization'] = SecureStorageService.authToken;
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) request.headers['X-App-Token'] = appToken;
  }

  Future<Resource<Product>> create(Product product, List<File> files) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products');
      final request = http.MultipartRequest('POST', url);
      _applyHeaders(request);
      for (final file in files) {
        request.files.add(http.MultipartFile(
          'files',
          http.ByteStream(file.openRead().cast()),
          await file.length(),
          filename: basename(file.path),
          contentType: MediaType('image', 'jpg'),
        ));
      }
      request.fields['name'] = product.name;
      request.fields['description'] = product.description;
      request.fields['price'] = product.price.toString();
      request.fields['id_category'] = product.idCategory.toString();
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Product.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<Product>>> getProductsByCategory(int idCategory) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products/category/$idCategory');
      final response = await http.get(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Product.fromJsonList(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Product>> update(int id, Product product, List<File>? files) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products/$id');
      final request = http.MultipartRequest('PUT', url);
      _applyHeaders(request);
      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          request.files.add(http.MultipartFile(
            'files[]',
            http.ByteStream(file.openRead().cast()),
            await file.length(),
            filename: basename(file.path),
            contentType: MediaType('image', 'jpg'),
          ));
        }
      }
      request.fields['name'] = product.name;
      request.fields['description'] = product.description;
      request.fields['price'] = product.price.toString();
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Product.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> delete(int id) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products/$id');
      final response = await http.delete(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(true);
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
