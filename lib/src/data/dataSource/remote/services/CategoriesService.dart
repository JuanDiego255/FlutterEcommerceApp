import 'dart:convert';
import 'dart:io';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/domain/models/Category.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class CategoriesService {

  Future<String> token;

  CategoriesService(this.token);

  Future<Resource<Category>> create(Category category, File file) async {
    try {
      // http://192.168.80.13:3000/users/5
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories'); 
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = await token;
      request.files.add(http.MultipartFile(
        'file',
        http.ByteStream(file.openRead().cast()),
        await file.length(),
        filename: basename(file.path),
        contentType: MediaType('image', 'jpg')
      ));
      request.fields['name'] = category.name;
      request.fields['description'] = category.description;
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Category categoryResponse = Category.fromJson(data);
        return Success(categoryResponse);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<Category>>> getCategories() async {
     try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories'); 
      Map<String, String> headers = { 
        "Content-Type": "application/json",
        "Authorization": await token
      };
      final response = await http.get(url, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<Category> categories = Category.fromJsonList(data);
        return Success(categories);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Category>> update(int id, Category category) async {
     try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories/$id');      
      Map<String, String> headers = { 
        "Content-Type": "application/json",
        "Authorization": await token
      };
      String body = json.encode({
        'name': category.name,
        'description': category.description,
      });
      final response = await http.put(url, headers: headers, body: body);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Category categoryResponse = Category.fromJson(data);
        return Success(categoryResponse);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

  

  Future<Resource<Category>> updateImage(int id, Category category, File file) async {
    try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories/$id'); 
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = await token;
      request.files.add(http.MultipartFile(
        'file',
        http.ByteStream(file.openRead().cast()),
        await file.length(),
        filename: basename(file.path),
        contentType: MediaType('image', 'jpg')
      ));
      request.fields['name'] = category.name;
      request.fields['description'] = category.description;
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Category categoryResponse = Category.fromJson(data);
        return Success(categoryResponse);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> delete(int id) async {
     try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/categories/$id');     
      Map<String, String> headers = { 
        "Content-Type": "application/json",
        "Authorization": await token
      };
      final response = await http.delete(url, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(true);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

}