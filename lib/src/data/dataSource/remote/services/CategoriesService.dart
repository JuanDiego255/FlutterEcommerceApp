import 'dart:convert';
import 'dart:io';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/Category.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class CategoriesService {

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

  Future<Resource<Category>> create(Category category, File file) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories');
      final request = http.MultipartRequest('POST', url);
      _applyHeaders(request);
      request.files.add(http.MultipartFile(
        'file',
        http.ByteStream(file.openRead().cast()),
        await file.length(),
        filename: basename(file.path),
        contentType: MediaType('image', 'jpg'),
      ));
      request.fields['name'] = category.name;
      request.fields['description'] = category.description;
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Category.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<Category>>> getCategories() async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories');
      final response = await http.get(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Category.fromJsonList(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Category>> update(int id, Category category) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories/$id');
      final body = json.encode({'name': category.name, 'description': category.description});
      final response = await http.put(url, headers: _headers, body: body);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Category.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Category>> updateImage(int id, Category category, File file) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories/$id');
      final request = http.MultipartRequest('PUT', url);
      _applyHeaders(request);
      request.files.add(http.MultipartFile(
        'file',
        http.ByteStream(file.openRead().cast()),
        await file.length(),
        filename: basename(file.path),
        contentType: MediaType('image', 'jpg'),
      ));
      request.fields['name'] = category.name;
      request.fields['description'] = category.description;
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Category.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> delete(int id) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories/$id');
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
