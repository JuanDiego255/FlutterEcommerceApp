class TenantConfig {
  final String domain;

  /// Vertical del tenant ('ecommerce' | 'barbershop'). Decide qué home
  /// renderiza la app al entrar a la tienda.
  final String type;

  /// Color de marca en hex (#RRGGBB) — usado solo si la función premium
  /// 'branding' está activa.
  final String? colorHex;

  /// Funciones premium habilitadas en la central. La app las refresca al
  /// cargar el home de barbería (fuente de verdad: BD central).
  final List<String> features;

  /// In-memory only — NEVER serialized to SharedPreferences.
  /// Stored in SecureStorageService (iOS Keychain / Android EncryptedSharedPrefs).
  final String? appToken;

  const TenantConfig({
    required this.domain,
    this.type = 'ecommerce',
    this.colorHex,
    this.features = const [],
    this.appToken,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> j) => TenantConfig(
        domain: j['domain'] as String? ?? '',
        type: j['type'] as String? ?? 'ecommerce',
        colorHex: j['color'] as String?,
        features: ((j['features'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
        // appToken intentionally NOT read here — loaded separately from SecureStorage.
        // Legacy: if 'app_token' is present in SharedPrefs it will be migrated by
        // TenantSession.initialize() and stripped from the stored JSON.
      );

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'type': type,
        'color': colorHex,
        'features': features,
        // appToken intentionally excluded — stored in SecureStorage, not SharedPrefs.
      };

  TenantConfig copyWith({
    String? domain,
    String? type,
    String? colorHex,
    List<String>? features,
    String? appToken,
  }) =>
      TenantConfig(
        domain: domain ?? this.domain,
        type: type ?? this.type,
        colorHex: colorHex ?? this.colorHex,
        features: features ?? this.features,
        appToken: appToken ?? this.appToken,
      );

  @override
  String toString() => 'TenantConfig(domain: $domain, type: $type)';
}
