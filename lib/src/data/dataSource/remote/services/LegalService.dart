import 'dart:convert';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/LegalContent.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

// Public legal service — no X-App-Token, no auth token.
// Reads from the public /api/legal/* endpoints.
class LegalService {
  String get _host => TenantSession.host;
  String get _tenant => _host.split('.').first;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Resource<LegalContent>> fetch(String type) async {
    try {
      final url = Uri.https(_host, '/api/legal/$type/$_tenant');
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(LegalContent.fromJson(body));
      }
      return Error(_parseError(res, 'Error al cargar el contenido'));
    } catch (e) {
      return Error(e.toString());
    }
  }

  String _parseError(http.Response res, String fallback) {
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
