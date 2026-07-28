import 'dart:convert';

import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantOption.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Directorio dinámico de tiendas para el selector de tenants.
///
/// Fuente: `GET https://{central}/api/app/tenants` (dominio central, los
/// tenants se habilitan desde el panel con la columna app_enabled).
///
/// Resiliencia:
/// 1. Respuesta exitosa → se usa y se cachea en SharedPreferences.
/// 2. Error de red → se usa el último listado cacheado.
/// 3. Sin caché → lista de respaldo quemada (las 4 tiendas históricas),
///    para que el selector nunca quede vacío por un problema del central.
class TenantDirectoryService {
  static const String _kCacheKey = 'tenant_directory_v1';

  /// Tiendas históricas, solo como último recurso sin red y sin caché.
  static const List<Map<String, dynamic>> _kFallback = [
    {
      'id': 'mitaicr',
      'name': 'Mitai CR',
      'subtitle': 'Ropa y accesorios para bebé',
      'location': 'Grecia, Alajuela',
      'domain': 'mitaicr.com',
      'type': 'ecommerce',
      'color': '#E91E8C',
    },
    {
      'id': 'muebleriasarchi',
      'name': 'Mueblería Sarchi',
      'subtitle': 'Muebles y decoración artesanal',
      'location': 'Sarchí, Alajuela',
      'domain': 'muebleriasarchi.com',
      'type': 'ecommerce',
      'color': '#795548',
    },
    {
      'id': 'solociclismocrc',
      'name': 'Solo Ciclismo',
      'subtitle': 'Equipos y accesorios de ciclismo',
      'location': 'Guápiles, Limón',
      'domain': 'solociclismocrc.safeworsolutions.com',
      'type': 'ecommerce',
      'color': '#1565C0',
    },
    {
      'id': 'futstorecr',
      'name': 'FUT Store',
      'subtitle': 'Tienda de fútbol y deportes',
      'location': 'Grecia, Alajuela',
      'domain': 'futstorecr.safeworsolutions.com',
      'type': 'ecommerce',
      'color': '#2E7D32',
    },
  ];

  Future<List<TenantOption>> fetch() async {
    try {
      final uri = Uri.https(ApiConfig.CENTRAL_HOST, '/api/app/tenants');
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final list = (body['tenants'] as List<dynamic>? ?? [])
            .map((e) => TenantOption.fromJson(e as Map<String, dynamic>))
            .where((t) => t.domain.isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          await _saveCache(list);
          return list;
        }
      }
    } catch (_) {
      // cae al caché / fallback
    }

    final cached = await _readCache();
    if (cached.isNotEmpty) return cached;

    return _kFallback.map(TenantOption.fromJson).toList();
  }

  Future<void> _saveCache(List<TenantOption> tenants) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCacheKey,
      json.encode(tenants.map((t) => t.toJson()).toList()),
    );
  }

  Future<List<TenantOption>> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCacheKey);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => TenantOption.fromJson(e as Map<String, dynamic>))
          .where((t) => t.domain.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
