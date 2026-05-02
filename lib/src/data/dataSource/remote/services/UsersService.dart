import 'dart:convert';
import 'dart:io';

import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

class UsersService {

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

  /// Updates the authenticated user's profile.
  /// [image] is ignored (users table has no image column yet).
  Future<Resource<User>> update(int id, User user, [File? image]) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/client/profile');
      final body = json.encode({
        'name':     user.name,
        'lastname': user.lastname,
        'phone':    user.phone,
      });
      final response = await http.put(url, headers: _headers, body: body);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(User.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
