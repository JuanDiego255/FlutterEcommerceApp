import 'dart:convert';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const _key = 'catalog_wishlist';

  static Future<List<CatalogProduct>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((s) => CatalogProduct.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> contains(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.any((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == productId;
    });
  }

  static Future<void> add(CatalogProduct product) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    final alreadyIn = jsonList.any((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == product.id;
    });
    if (alreadyIn) return;
    jsonList.add(json.encode(product.toJson()));
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> remove(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    jsonList.removeWhere((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return m['id'] == productId;
    });
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
