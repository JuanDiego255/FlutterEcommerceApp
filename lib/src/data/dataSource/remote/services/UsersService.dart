import 'dart:convert';
import 'dart:io';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class UsersService {

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': SecureStorageService.authToken,
    };
    final appToken = TenantSession.appToken;
    if (appToken != null && appToken.isNotEmpty) h['X-App-Token'] = appToken;
    return h;
  }

  Future<Resource<User>> update(int id, User user) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/users/$id');
      final body = json.encode({
        'name': user.name,
        'lastname': user.lastname,
        'phone': user.phone,
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

  Future<Resource<User>> updateImage(int id, User user, File file) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/users/upload/$id');
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = SecureStorageService.authToken;
      final appToken = TenantSession.appToken;
      if (appToken != null && appToken.isNotEmpty) request.headers['X-App-Token'] = appToken;
      request.files.add(http.MultipartFile(
        'file',
        http.ByteStream(file.openRead().cast()),
        await file.length(),
        filename: basename(file.path),
        contentType: MediaType('image', 'jpg'),
      ));
      request.fields['user'] = json.encode({
        'name': user.name,
        'lastname': user.lastname,
        'phone': user.phone,
      });
      final response = await request.send();
      final data = json.decode(await response.stream.transform(utf8.decoder).first);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(User.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
