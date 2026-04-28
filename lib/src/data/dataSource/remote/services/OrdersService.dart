import 'dart:convert';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

class OrdersService {

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': SecureStorageService.authToken,
    };
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) h['X-App-Token'] = appToken;
    return h;
  }

  Future<Resource<List<Order>>> getOrders() async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/orders');
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

  Future<Resource<List<Order>>> getOrdersByClient(int idClient) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/orders/$idClient');
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
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/orders/$id');
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
}
