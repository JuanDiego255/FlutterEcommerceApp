import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for sensitive credentials.
///
/// - Auth token (Sanctum/JWT from login) expires after [_kMaxAuthAgeDays] days.
/// - App token (X-App-Token for admin API access) has no forced expiry.
/// - All data stored in iOS Keychain / Android EncryptedSharedPreferences.
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _kAuthToken    = 'sw_auth_token';
  static const _kAuthIssuedAt = 'sw_auth_issued_at';
  static const _kAppToken     = 'sw_app_token';

  static const int _kMaxAuthAgeDays = 30;

  // ─── In-memory cache ──────────────────────────────────────────────────────
  // Primed at app start via initializeCache(); updated immediately on every
  // login/logout so all services always get the current token synchronously.

  static String? _cachedAuthToken;

  /// Synchronous getter — current token, zero async latency.
  static String get authToken => _cachedAuthToken ?? '';

  /// Call once at startup (after TenantSession.initialize) to load the
  /// persisted token into the in-memory cache.
  static Future<void> initializeCache() async {
    if (await _isAuthTokenExpired()) {
      await clearAuthToken();
      return;
    }
    _cachedAuthToken = await _storage.read(key: _kAuthToken);
  }

  // ─── Auth token ───────────────────────────────────────────────────────────

  static Future<void> saveAuthToken(String token) async {
    _cachedAuthToken = token; // immediate in-memory update — no async delay
    await _storage.write(key: _kAuthToken, value: token);
    await _storage.write(
      key: _kAuthIssuedAt,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Returns the stored auth token, or null if expired / not set.
  static Future<String?> getAuthToken() async {
    if (_cachedAuthToken != null) return _cachedAuthToken;
    if (await _isAuthTokenExpired()) {
      await clearAuthToken();
      return null;
    }
    _cachedAuthToken = await _storage.read(key: _kAuthToken);
    return _cachedAuthToken;
  }

  static Future<bool> _isAuthTokenExpired() async {
    final raw = await _storage.read(key: _kAuthIssuedAt);
    if (raw == null) return true;
    final issuedAt = int.tryParse(raw) ?? 0;
    final elapsed  = DateTime.now().millisecondsSinceEpoch - issuedAt;
    return elapsed > const Duration(days: _kMaxAuthAgeDays).inMilliseconds;
  }

  static Future<void> clearAuthToken() async {
    _cachedAuthToken = null;
    await _storage.delete(key: _kAuthToken);
    await _storage.delete(key: _kAuthIssuedAt);
  }

  // ─── App token ────────────────────────────────────────────────────────────

  static Future<void> saveAppToken(String token) async {
    await _storage.write(key: _kAppToken, value: token);
  }

  static Future<String?> getAppToken() async {
    return _storage.read(key: _kAppToken);
  }

  static Future<void> clearAppToken() async {
    await _storage.delete(key: _kAppToken);
  }

  // ─── Clear all ────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await clearAuthToken();
    await clearAppToken();
  }
}
