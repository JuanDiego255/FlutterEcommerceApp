import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

class MitaiProduct {
  int? id;
  String name;
  String? code;
  String? description;
  double price;
  double? mayorPrice;
  int? discount;
  int manageStock;
  int? totalStock;
  String? availableAttr;
  String? image;

  MitaiProduct({
    this.id,
    required this.name,
    this.code,
    this.description,
    required this.price,
    this.mayorPrice,
    this.discount,
    required this.manageStock,
    this.totalStock,
    this.availableAttr,
    this.image,
  });

  String get imageUrl =>
      image != null && image!.isNotEmpty ? 'https://${TenantSession.host}/file/${image!}' : '';

  List<String> get attrList =>
      availableAttr != null && availableAttr!.isNotEmpty
          ? availableAttr!.split(',').where((s) => s.isNotEmpty).toList()
          : [];

  factory MitaiProduct.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return MitaiProduct(
      id: parseInt(json["id"]),
      name: json["name"] ?? '',
      code: json["code"]?.toString(),
      description: json["description"]?.toString(),
      price: parseDouble(json["price"]),
      mayorPrice: json["mayor_price"] != null ? parseDouble(json["mayor_price"]) : null,
      discount: parseInt(json["discount"]),
      manageStock: parseInt(json["manage_stock"]) ?? 0,
      totalStock: parseInt(json["total_stock"]),
      availableAttr: json["available_attr"]?.toString(),
      image: json["image"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "code": code,
        "description": description,
        "price": price,
        "mayor_price": mayorPrice,
        "discount": discount,
        "manage_stock": manageStock,
        "total_stock": totalStock,
        "available_attr": availableAttr,
        "image": image,
      };

  static List<MitaiProduct> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((item) => MitaiProduct.fromJson(item)).toList();
  }
}
