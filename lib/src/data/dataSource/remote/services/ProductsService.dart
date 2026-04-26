import 'dart:convert';
import 'dart:io';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class ProductsService {

  Future<String> token;

  ProductsService(this.token);

  Future<Resource<Product>> create(Product product, List<File> files) async {
    try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products'); 
      
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = await token;
      files.forEach((file) async {
        request.files.add(http.MultipartFile(
          'files',
          http.ByteStream(file.openRead().cast()),
          await file.length(),
          filename: basename(file.path),
          contentType: MediaType('image', 'jpg')
        ));
      });
      request.fields['name'] = product.name;
      request.fields['description'] = product.description;
      request.fields['price'] = product.price.toString();
      request.fields['id_category'] = product.idCategory.toString();
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Product productResponse = Product.fromJson(data);
        return Success(productResponse);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

   Future<Resource<List<Product>>> getProductsByCategory(int idCategory) async {
     try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products/category/$idCategory'); 
      Map<String, String> headers = { 
        "Content-Type": "application/json",
        "Authorization": await token
      };
      final response = await http.get(url, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<Product> products = Product.fromJsonList(data);
        return Success(products);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Product>> update(int id, Product product, List<File>? files) async {
    try {
      // http://192.168.80.13:3000/users/5
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products/${id}'); 
      
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = await token;
      if (files != null) {
        if (files.isNotEmpty) {
          files.forEach((file) async {
            request.files.add(http.MultipartFile(
              'files[]',
              http.ByteStream(file.openRead().cast()),
              await file.length(),
              filename: basename(file.path),
              contentType: MediaType('image', 'jpg')
            ));
          });
        }
      }
      
      request.fields['name'] = product.name;
      request.fields['description'] = product.description;
      request.fields['price'] = product.price.toString();
      
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Product productResponse = Product.fromJson(data);
        return Success(productResponse);
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
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/products/$id');      
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