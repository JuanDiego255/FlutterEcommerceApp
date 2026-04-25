import 'dart:convert';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const _key = 'catalog_wishlist';

  static Future<List<WishlistItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    final items = <WishlistItem>[];
    for (final s in jsonList) {
      try {
        items.add(WishlistItem.fromJson(json.decode(s) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return items;
  }

  static Future<bool> contains(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.any((s) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        final id = m.containsKey('product')
            ? (m['product'] as Map<String, dynamic>)['id']
            : m['id'];
        return id == productId;
      } catch (_) {
        return false;
      }
    });
  }

  static Future<void> add(WishlistItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    final alreadyIn = jsonList.any((s) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        final id = m.containsKey('product')
            ? (m['product'] as Map<String, dynamic>)['id']
            : m['id'];
        return id == item.product.id;
      } catch (_) {
        return false;
      }
    });
    if (alreadyIn) return;
    jsonList.add(json.encode(item.toJson()));
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> remove(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    jsonList.removeWhere((s) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        final id = m.containsKey('product')
            ? (m['product'] as Map<String, dynamic>)['id']
            : m['id'];
        return id == productId;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, jsonList);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
