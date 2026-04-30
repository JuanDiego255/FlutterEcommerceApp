import 'dart:convert';

Product productFromJson(String str) => Product.fromJson(json.decode(str));

String productToJson(Product data) => json.encode(data.toJson());

class Product {
    int? id;
    String name;
    String description;
    String? image1;
    String? image2;
    int idCategory;
    double price;
    int? quantity;
    String? selectedVariant;
    double? variantPrice;

    // Effective price: use variant price when set, otherwise base price
    double get effectivePrice =>
        (variantPrice != null && variantPrice! > 0) ? variantPrice! : price;

    Product({
        this.id,
        required this.name,
        required this.description,
        this.image1,
        this.image2,
        required this.idCategory,
        required this.price,
        this.quantity,
        this.selectedVariant,
        this.variantPrice,
    });

    static List<Product> fromJsonList(List<dynamic> jsonList) {
      List<Product> toList = [];
      jsonList.forEach((item) {
        Product product = Product.fromJson(item);
        toList.add(product);
      });
      return toList;
    }

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"],
        name: json["name"] ?? '',
        description: json["description"] ?? '',
        image1: json["image1"],
        image2: json["image2"],
        idCategory: json["id_category"] is String
            ? int.tryParse(json["id_category"]) ?? 0
            : (json["id_category"] as int? ?? 0),
        price: json["price"] is String
              ? double.parse(json["price"])
              : json["price"] is int
                ? (json["price"] as int).toDouble()
                : (json["price"] as double? ?? 0.0),
        quantity: json["quantity"],
        selectedVariant: json["selected_variant"],
        variantPrice: json["variant_price"] is String
            ? double.tryParse(json["variant_price"])
            : json["variant_price"] is int
                ? (json["variant_price"] as int).toDouble()
                : json["variant_price"] as double?,
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "image1": image1,
        "image2": image2,
        "id_category": idCategory,
        "price": price,
        "quantity": quantity,
        "selected_variant": selectedVariant,
        "variant_price": variantPrice,
    };
}