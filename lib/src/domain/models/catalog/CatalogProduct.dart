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
  final List<String> availableAttrs;

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
    required this.availableAttrs,
  });

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

    final rawAttrs = j['available_attr'] as String? ?? '';
    final attrs = rawAttrs.isNotEmpty
        ? rawAttrs.split(',').where((s) => s.isNotEmpty).toList()
        : <String>[];

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
      availableAttrs: attrs,
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
        'available_attr': availableAttrs.join(','),
      };

  static List<CatalogProduct> fromJsonList(List<dynamic> list) =>
      list.map((e) => CatalogProduct.fromJson(e as Map<String, dynamic>)).toList();
}
