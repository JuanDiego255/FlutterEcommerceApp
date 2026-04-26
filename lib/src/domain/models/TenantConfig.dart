class TenantConfig {
  final String domain;

  /// In-memory only — NEVER serialized to SharedPreferences.
  /// Stored in SecureStorageService (iOS Keychain / Android EncryptedSharedPrefs).
  final String? appToken;

  const TenantConfig({
    required this.domain,
    this.appToken,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> j) => TenantConfig(
        domain: j['domain'] as String? ?? '',
        // appToken intentionally NOT read here — loaded separately from SecureStorage.
        // Legacy: if 'app_token' is present in SharedPrefs it will be migrated by
        // TenantSession.initialize() and stripped from the stored JSON.
      );

  Map<String, dynamic> toJson() => {
        'domain': domain,
        // appToken intentionally excluded — stored in SecureStorage, not SharedPrefs.
      };

  TenantConfig copyWith({String? domain, String? appToken}) => TenantConfig(
        domain: domain ?? this.domain,
        appToken: appToken ?? this.appToken,
      );

  @override
  String toString() => 'TenantConfig(domain: $domain)';
}
