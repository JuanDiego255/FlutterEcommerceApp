import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

class CatalogNavItem {
  final int id;
  final String name;
  final String? image;

  const CatalogNavItem({
    required this.id,
    required this.name,
    this.image,
  });

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    return 'https://${TenantSession.host}/file/$image';
  }

  factory CatalogNavItem.fromJson(Map<String, dynamic> j) => CatalogNavItem(
        id: j['id'] as int? ?? 0,
        name: j['name']?.toString() ?? '',
        image: j['image']?.toString(),
      );

  static List<CatalogNavItem> fromJsonList(List<dynamic> list) =>
      list.map((e) => CatalogNavItem.fromJson(e as Map<String, dynamic>)).toList();
}
