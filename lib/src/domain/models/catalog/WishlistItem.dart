import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';

class WishlistItem {
  final CatalogProduct product;
  final String? variantLabel;
  final double? variantPrice;

  const WishlistItem({
    required this.product,
    this.variantLabel,
    this.variantPrice,
  });

  /// Effective display price: variant override → discounted → base.
  double get displayPrice {
    if (variantPrice != null && variantPrice! > 0) return variantPrice!;
    return product.hasDiscount ? product.finalPrice : product.price;
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        if (variantLabel != null) 'variant_label': variantLabel,
        if (variantPrice != null) 'variant_price': variantPrice,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> j) {
    // New format: { product: {...}, variant_label: ..., variant_price: ... }
    if (j.containsKey('product')) {
      return WishlistItem(
        product: CatalogProduct.fromJson(j['product'] as Map<String, dynamic>),
        variantLabel: j['variant_label'] as String?,
        variantPrice: (j['variant_price'] as num?)?.toDouble(),
      );
    }
    // Legacy format: raw CatalogProduct JSON (no variant info)
    return WishlistItem(product: CatalogProduct.fromJson(j));
  }
}
