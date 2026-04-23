class ProductVariant {
  int combinationId;
  String label;
  int stock;
  double price;
  int manageStock;

  ProductVariant({
    required this.combinationId,
    required this.label,
    required this.stock,
    required this.price,
    required this.manageStock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val, {int defaultVal = 0}) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    return ProductVariant(
      combinationId: parseInt(json["combination_id"]),
      label: json["label"] ?? '',
      stock: parseInt(json["stock"]),
      price: parseDouble(json["price"]),
      manageStock: parseInt(json["manage_stock"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "combination_id": combinationId,
        "label": label,
        "stock": stock,
        "price": price,
        "manage_stock": manageStock,
      };

  static List<ProductVariant> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((item) => ProductVariant.fromJson(item)).toList();
  }
}
