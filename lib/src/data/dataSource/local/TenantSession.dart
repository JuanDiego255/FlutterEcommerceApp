import 'dart:convert';

import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that holds the active tenant configuration.
///
/// Sensitive data (appToken) lives exclusively in [SecureStorageService]
/// (iOS Keychain / Android EncryptedSharedPreferences).
/// Non-sensitive data (domain) lives in plain SharedPreferences.
class TenantSession {
  TenantSession._();

  static const String _kKey = 'tenant_config_v1';
  static TenantConfig? _config;

  /// Loads tenant config from SharedPreferences and the app token from
  /// SecureStorageService. Automatically migrates any legacy app token found
  /// in SharedPreferences to the secure keychain.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;

    try {
      final map = json.decode(raw) as Map<String, dynamic>;

      // ── Legacy migration: move appToken from SharedPrefs → SecureStorage ──
      final legacyToken = map['app_token'] as String?;
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await SecureStorageService.saveAppToken(legacyToken);
        map.remove('app_token');
        await prefs.setString(_kKey, json.encode(map));
      }

      // ── Load appToken from secure storage ──────────────────────────────────
      final appToken = await SecureStorageService.getAppToken();

      _config = TenantConfig(
        domain: map['domain'] as String? ?? '',
        appToken: appToken,
      );
    } catch (_) {
      _config = null;
    }
  }

  /// Persists [config]. The appToken is saved to SecureStorageService; the
  /// domain is saved to SharedPreferences.
  static Future<void> save(TenantConfig config) async {
    if (config.appToken != null && config.appToken!.isNotEmpty) {
      await SecureStorageService.saveAppToken(config.appToken!);
    }
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, json.encode(config.toJson()));
  }

  /// Clears the full session from both SharedPreferences and SecureStorageService.
  static Future<void> clear() async {
    _config = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
    await prefs.remove('user');
    await SecureStorageService.clearAll();
  }

  static bool    get isConfigured   => _config != null && _config!.domain.isNotEmpty;
  static bool    get hasAdminAccess => _config?.appToken?.isNotEmpty ?? false;
  static String  get host           => _config?.domain ?? '';
  static String? get appToken       => _config?.appToken;
  static TenantConfig? get config   => _config;
}
