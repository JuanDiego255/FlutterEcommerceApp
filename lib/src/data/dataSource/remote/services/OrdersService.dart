import 'dart:convert';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

class OrdersService {

  Future<String> token;

  OrdersService(this.token);

  Future<Resource<List<Order>>> getOrders() async {
     try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/orders'); 
      Map<String, String> headers = { 
        "Content-Type": "application/json",
        "Authorization": await token
      };
      final response = await http.get(url, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<Order> orders = Order.fromJsonList(data);
        return Success(orders);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<Order>>> getOrdersByClient(int idClient) async {
     try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/orders/$idClient'); 
      Map<String, String> headers = { 
        "Content-Type": "application/json",
        "Authorization": await token
      };
      final response = await http.get(url, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<Order> orders = Order.fromJsonList(data);
        return Success(orders);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

   Future<Resource<Order>> updateStatus(int id) async {
     try {
      Uri url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/orders/$id');      
      Map<String, String> headers = { 
        "Content-Type": "application/json",
        "Authorization": await token
      };
      final response = await http.put(url, headers: headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Order orderResponse = Order.fromJson(data);
        return Success(orderResponse);
      }
      else { // ERROR
        return Error(listToString(data['message']));
      }      
    } catch (e) {
      return Error(e.toString());
    }
  }

}