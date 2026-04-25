import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

class CatalogVariant {
  final int combinationId;
  final String label;
  final int stock;
  final double price;
  final int manageStock;

  const CatalogVariant({
    required this.combinationId,
    required this.label,
    required this.stock,
    required this.price,
    required this.manageStock,
  });

  bool get hasCustomPrice => price > 0;
  bool get inStock => manageStock == 0 || stock > 0;

  factory CatalogVariant.fromJson(Map<String, dynamic> j) {
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

    return CatalogVariant(
      combinationId: _i(j['combination_id']),
      label: j['label']?.toString() ?? '',
      stock: _i(j['stock']),
      price: _d(j['price']),
      manageStock: _i(j['manage_stock'], def: 1),
    );
  }

  static List<CatalogVariant> fromJsonList(List<dynamic> list) =>
      list.map((e) => CatalogVariant.fromJson(e as Map<String, dynamic>)).toList();
}

class CatalogProductDetail {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final double price;
  final double? mayorPrice;
  final int discount;
  final int manageStock;
  final int stock;
  final List<String> images;
  final List<CatalogVariant> variants;
  final List<String> categories;

  const CatalogProductDetail({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.price,
    this.mayorPrice,
    required this.discount,
    required this.manageStock,
    required this.stock,
    required this.images,
    required this.variants,
    required this.categories,
  });

  bool get hasDiscount => discount > 0;
  double get finalPrice => hasDiscount ? price * (1 - discount / 100) : price;
  double get savedAmount => hasDiscount ? price - finalPrice : 0;

  List<String> get imageUrls => images
      .map((img) => 'https://${TenantSession.host}/file/$img')
      .toList();

  factory CatalogProductDetail.fromJson(Map<String, dynamic> j) {
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

    final rawImages = j['images'] as List<dynamic>? ?? [];
    final rawVariants = j['variants'] as List<dynamic>? ?? [];
    final rawCategories = j['categories'] as List<dynamic>? ?? [];

    return CatalogProductDetail(
      id: _i(j['id']),
      name: j['name']?.toString() ?? '',
      code: j['code']?.toString(),
      description: j['description']?.toString(),
      price: _d(j['price']),
      mayorPrice: j['mayor_price'] != null ? _d(j['mayor_price']) : null,
      discount: _i(j['discount']),
      manageStock: _i(j['manage_stock']),
      stock: _i(j['stock']),
      images: rawImages.map((e) => e.toString()).toList(),
      variants: CatalogVariant.fromJsonList(rawVariants),
      categories: rawCategories.map((e) => e.toString()).toList(),
    );
  }
}
