import 'dart:convert';

import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that holds the active tenant configuration.
///
/// Sensitive data (appToken) lives exclusively in [SecureStorageService]
/// (iOS Keychain / Android EncryptedSharedPreferences).
/// Non-sensitive data (domain, type, default flag) lives in plain
/// SharedPreferences.
class TenantSession {
  TenantSession._();

  static const String _kKey = 'tenant_config_v1';
  static const String _kDefaultKey = 'tenant_default_v1';
  static TenantConfig? _config;
  static bool _defaultEnabled = false;

  /// Loads tenant config from SharedPreferences and the app token from
  /// SecureStorageService. Automatically migrates any legacy app token found
  /// in SharedPreferences to the secure keychain.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultEnabled = prefs.getBool(_kDefaultKey) ?? false;
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

      _config = TenantConfig.fromJson(map).copyWith(appToken: appToken);
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

  /// Marca (o desmarca) la tienda actual como predeterminada: al abrir la
  /// app se salta el selector y entra directo al home de la tienda.
  static Future<void> setDefaultEnabled(bool enabled) async {
    _defaultEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDefaultKey, enabled);
  }

  /// Clears the full session from both SharedPreferences and SecureStorageService.
  static Future<void> clear() async {
    _config = null;
    _defaultEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
    await prefs.remove(_kDefaultKey);
    await prefs.remove('user');
    await SecureStorageService.clearAll();
  }

  /// Guarda dominio/token conservando la vertical, el color y las funciones
  /// del tenant si el dominio no cambió. Lo usan las pantallas que solo
  /// configuran servidor o token (AdminTokenPage, config manual del login):
  /// sin esto el tenant volvería a 'ecommerce' y la app perdería el modo
  /// barbería.
  static Future<void> saveKeepingVertical({
    required String domain,
    String? appToken,
  }) async {
    final current = _config;
    final sameDomain = current != null && current.domain == domain;
    await save(TenantConfig(
      domain: domain,
      type: sameDomain ? current.type : 'ecommerce',
      colorHex: sameDomain ? current.colorHex : null,
      features: sameDomain ? current.features : const [],
      appToken: appToken ?? (sameDomain ? current.appToken : null),
    ));
  }

  /// Refresca las funciones premium (y opcionalmente el color de marca) del
  /// tenant activo — la fuente de verdad es la BD central, así que la app
  /// las actualiza cada vez que el backend las publica (p. ej. al cargar el
  /// home de barbería).
  static Future<void> updateFeatures(List<String> features,
      {String? colorHex}) async {
    final current = _config;
    if (current == null) return;
    await save(current.copyWith(
      features: features,
      colorHex: colorHex ?? current.colorHex,
    ));
  }

  static bool    get isConfigured   => _config != null && _config!.domain.isNotEmpty;
  static bool    get defaultEnabled => _defaultEnabled;
  static bool    get hasAdminAccess => _config?.appToken?.isNotEmpty ?? false;
  static String  get host           => _config?.domain ?? '';
  static String? get appToken       => _config?.appToken;
  static String  get appType        => _config?.type ?? 'ecommerce';
  static bool    get isBarbershop   => appType == 'barbershop';
  static TenantConfig? get config   => _config;

  /// Funciones premium del tenant activo (claves del catálogo central).
  static List<String> get features => _config?.features ?? const [];
  static bool hasFeature(String key) => features.contains(key);

  /// Color de marca del tenant, solo si la función premium 'branding'
  /// está activa. Null → la app usa el acento dorado por defecto.
  static String? get brandColorHex =>
      hasFeature('branding') ? _config?.colorHex : null;

  /// Ruta home según la vertical del tenant activo.
  static String get homeRoute => isBarbershop ? 'barber/home' : 'catalog/home';
}
