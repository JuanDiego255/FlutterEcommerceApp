import 'dart:convert';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

class AddressService {

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': SecureStorageService.authToken,
    };
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) h['X-App-Token'] = appToken;
    return h;
  }

  Future<Resource<Address>> create(Address address) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/address');
      final response = await http.post(url, headers: _headers, body: json.encode(address.toJson()));
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Address.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<List<Address>>> getUserAddress(int idUser) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/address/user/$idUser');
      final response = await http.get(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(Address.fromJsonList(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<bool>> delete(int id) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/address/$id');
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
