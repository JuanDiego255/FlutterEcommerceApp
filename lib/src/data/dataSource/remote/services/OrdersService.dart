import 'dart:convert';

import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class OrdersService {

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = SecureStorageService.authToken;
    if (token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) h['X-App-Token'] = appToken;
    return h;
  }

  Future<Resource<List<Order>>> getOrders() async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/admin/orders');
      final response = await http.get(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Order.fromJsonList(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Order>> updateStatus(int id) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/admin/orders/$id/approve');
      final response = await http.put(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Order.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<Order>>> getOrdersByClient(int idClient) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/client/orders');
      final response = await http.get(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Order.fromJsonList(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Order>> guestOrder({
    required String name,
    required String email,
    required String telephone,
    required String country,
    required String province,
    required String city,
    required String addressTwo,
    required String address,
    required String postalCode,
    required List<Product> products,
    XFile? proofImage,
  }) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/orders/guest');
      final itemsJson = json.encode(products.map((p) => {
        'product_id': p.id,
        'quantity': p.quantity ?? 1,
        'price': p.effectivePrice,
      }).toList());

      http.Response response;

      if (proofImage != null) {
        // Multipart request when a proof image is attached
        final headers = Map<String, String>.from(_headers)
          ..remove('Content-Type'); // let http set the multipart boundary
        final req = http.MultipartRequest('POST', url)
          ..headers.addAll(headers)
          ..fields['name']        = name
          ..fields['email']       = email
          ..fields['telephone']   = telephone
          ..fields['country']     = country
          ..fields['province']    = province
          ..fields['city']        = city
          ..fields['address_two'] = addressTwo
          ..fields['address']     = address
          ..fields['postal_code'] = postalCode
          ..fields['items']       = itemsJson;

        final ext = proofImage.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : 'jpeg';
        req.files.add(await http.MultipartFile.fromPath(
          'image',
          proofImage.path,
          contentType: MediaType('image', mimeType),
        ));
        final streamed = await req.send();
        response = await http.Response.fromStream(streamed);
      } else {
        // Regular JSON POST
        final body = {
          'name': name,
          'email': email,
          'telephone': telephone,
          'country': country,
          'province': province,
          'city': city,
          'address_two': addressTwo,
          'address': address,
          'postal_code': postalCode,
          'items': products.map((p) => {
            'product_id': p.id,
            'quantity': p.quantity ?? 1,
            'price': p.effectivePrice,
          }).toList(),
        };
        response = await http.post(url, headers: _headers, body: json.encode(body));
      }

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Order.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<Order>> createOrder(Address address, List<Product> products) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/client/orders');
      final body = {
        'address_id': address.id,
        'items': products.map((p) => {
          'product_id': p.id,
          'quantity': p.quantity ?? 1,
          'price': p.effectivePrice,
        }).toList(),
      };
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Order.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
