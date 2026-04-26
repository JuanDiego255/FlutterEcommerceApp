import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

class CatalogProduct {
  final int id;
  final String name;
  final String? code;
  final double price;
  final double? mayorPrice;
  final int discount;
  final int manageStock;
  final int totalStock;
  final String? image;
  // Map of attribute name → list of values  e.g. {'Tallas': ['XS','S'], 'Colores': ['Blanco']}
  final Map<String, List<String>> attrGroups;

  const CatalogProduct({
    required this.id,
    required this.name,
    this.code,
    required this.price,
    this.mayorPrice,
    required this.discount,
    required this.manageStock,
    required this.totalStock,
    this.image,
    this.attrGroups = const {},
  });

  // Flat list of all variant values across all attributes (used for wishlist picking)
  List<String> get availableAttrs =>
      attrGroups.values.expand((v) => v).toList();

  bool get hasDiscount => discount > 0;
  double get finalPrice =>
      hasDiscount ? price * (1 - discount / 100) : price;
  double get savedAmount => hasDiscount ? price - finalPrice : 0;

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    return 'https://${TenantSession.host}/file/$image';
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> j) {
    double _d(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int _i(dynamic v, {int def = 0}) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    // Parse grouped attributes from "AttrName|value,AttrName|value2" format
    final rawGroups = j['available_attr_groups'] as String? ?? '';
    final Map<String, List<String>> attrGroups = {};
    if (rawGroups.isNotEmpty) {
      for (final entry in rawGroups.split(',')) {
        final idx = entry.indexOf('|');
        if (idx > 0) {
          final name = entry.substring(0, idx).trim();
          final val  = entry.substring(idx + 1).trim();
          if (name.isNotEmpty && val.isNotEmpty) {
            attrGroups.putIfAbsent(name, () => []).add(val);
          }
        }
      }
    }

    return CatalogProduct(
      id: _i(j['id']),
      name: j['name']?.toString() ?? '',
      code: j['code']?.toString(),
      price: _d(j['price']),
      mayorPrice: j['mayor_price'] != null ? _d(j['mayor_price']) : null,
      discount: _i(j['discount']),
      manageStock: _i(j['manage_stock']),
      totalStock: _i(j['total_stock']),
      image: j['image']?.toString(),
      attrGroups: attrGroups,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'price': price,
        'mayor_price': mayorPrice,
        'discount': discount,
        'manage_stock': manageStock,
        'total_stock': totalStock,
        'image': image,
        'available_attr_groups': attrGroups.entries
            .expand((e) => e.value.map((v) => '${e.key}|$v'))
            .join(','),
      };

  static List<CatalogProduct> fromJsonList(List<dynamic> list) =>
      list.map((e) => CatalogProduct.fromJson(e as Map<String, dynamic>)).toList();
}
