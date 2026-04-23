import 'dart:convert';

class TenantConfig {
  final String domain;
  final String appToken;

  const TenantConfig({
    required this.domain,
    required this.appToken,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> j) => TenantConfig(
        domain: j['domain'] as String? ?? '',
        appToken: j['app_token'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'app_token': appToken,
      };

  @override
  String toString() => 'TenantConfig(domain: $domain)';
}
