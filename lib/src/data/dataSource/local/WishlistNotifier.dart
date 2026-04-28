import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:flutter/foundation.dart';

/// Singleton ChangeNotifier that wraps WishlistService.
/// All screens listen to this notifier so heart icons stay in sync.
class WishlistNotifier extends ChangeNotifier {
  WishlistNotifier._();
  static final WishlistNotifier instance = WishlistNotifier._();

  final Set<int> _ids = {};
  String _tenant = '';

  /// Call once at startup (after TenantSession.initialize()) and again
  /// whenever the active tenant changes.
  Future<void> reload() async {
    final tenant = TenantSession.host;
    if (tenant != _tenant) {
      _ids.clear();
      _tenant = tenant;
    }
    final items = await WishlistService.getAll();
    _ids
      ..clear()
      ..addAll(items.map((i) => i.product.id));
    notifyListeners();
  }

  bool contains(int productId) => _ids.contains(productId);

  Future<void> add(WishlistItem item) async {
    await WishlistService.add(item);
    _ids.add(item.product.id);
    notifyListeners();
  }

  Future<void> remove(int productId) async {
    await WishlistService.remove(productId);
    _ids.remove(productId);
    notifyListeners();
  }

  Future<void> clear() async {
    await WishlistService.clear();
    _ids.clear();
    notifyListeners();
  }

  Future<void> toggle(WishlistItem item) async {
    if (contains(item.product.id)) {
      await remove(item.product.id);
    } else {
      await add(item);
    }
  }
}
