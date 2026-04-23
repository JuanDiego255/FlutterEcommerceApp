import 'dart:convert';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TenantSession {
  TenantSession._();

  static const String _kKey = 'tenant_config_v1';
  static TenantConfig? _config;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      try {
        _config = TenantConfig.fromJson(json.decode(raw) as Map<String, dynamic>);
      } catch (_) {
        _config = null;
      }
    }
  }

  static Future<void> save(TenantConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, json.encode(config.toJson()));
  }

  static Future<void> clear() async {
    _config = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
    await prefs.remove('user');
  }

  static bool get isConfigured => _config != null && _config!.domain.isNotEmpty;
  static String get host => _config?.domain ?? '';
  static String? get appToken => _config?.appToken;
  static TenantConfig? get config => _config;
}
