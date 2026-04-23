import 'dart:convert';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';

class AuthService {

  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (TenantSession.appToken?.isNotEmpty == true)
      'X-App-Token': TenantSession.appToken!,
  };

  Future<Resource<AuthResponse>> login(String email, String password) async {
    try {
      final url = Uri.https(ApiConfig.BASE_URL, '/api/login');
      final response = await http.post(
        url,
        headers: _baseHeaders,
        body: json.encode({'email': email, 'password': password}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(AuthResponse.fromJson(data));
      }
      return Error(data['message']?.toString() ?? 'Credenciales inválidas');
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<AuthResponse>> register(User user) async {
    try {
      final url = Uri.https(ApiConfig.BASE_URL, '/api/auth/register');
      final response = await http.post(
        url,
        headers: _baseHeaders,
        body: json.encode(user),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(AuthResponse.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
