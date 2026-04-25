import 'CatalogNavItem.dart';
import 'CatalogProduct.dart';
import 'CatalogTenantInfo.dart';

class CatalogSocialLink {
  final int id;
  final String name;
  final String? url;

  const CatalogSocialLink({required this.id, required this.name, this.url});

  factory CatalogSocialLink.fromJson(Map<String, dynamic> j) => CatalogSocialLink(
        id: j['id'] as int? ?? 0,
        name: j['social_network']?.toString() ?? '',
        url: j['url']?.toString(),
      );
}

class CatalogHomeData {
  final CatalogTenantInfo tenantInfo;
  final String navType;
  final List<CatalogNavItem> navItems;
  final List<CatalogProduct> featured;
  final List<CatalogSocialLink> social;

  const CatalogHomeData({
    required this.tenantInfo,
    required this.navType,
    required this.navItems,
    required this.featured,
    required this.social,
  });

  factory CatalogHomeData.fromJson(Map<String, dynamic> j) => CatalogHomeData(
        tenantInfo: CatalogTenantInfo.fromJson(
            j['tenant_info'] as Map<String, dynamic>? ?? {}),
        navType: j['nav_type']?.toString() ?? 'categories',
        navItems: CatalogNavItem.fromJsonList(
            j['nav_items'] as List<dynamic>? ?? []),
        featured: CatalogProduct.fromJsonList(
            j['featured'] as List<dynamic>? ?? []),
        social: (j['social'] as List<dynamic>? ?? [])
            .map((e) => CatalogSocialLink.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
