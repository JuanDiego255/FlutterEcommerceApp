import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SharedPref.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/repository/ShoppingBagRepository.dart';

class ShoppingBagRepositoryImpl implements ShoppingBagRepository {

  SharedPref sharedPref;

  ShoppingBagRepositoryImpl(this.sharedPref);

  // Scoped key: prevents mixing carts between tenants or users.
  // Guest uses "guest"; logged-in users use the first 8 chars of their token hash.
  String get _cartKey {
    final tenant = TenantSession.host.replaceAll('.', '_');
    final token = SecureStorageService.authToken;
    final userScope = token.isNotEmpty ? token.hashCode.toUnsigned(32).toRadixString(16) : 'guest';
    return 'shopping_bag_${tenant}_$userScope';
  }

  @override
  Future<void> add(Product product) async {
    final data = await sharedPref.read(_cartKey);
    List<Product> selectedProducts = [];
    if (data == null) {
      product.quantity ??= 1;
      selectedProducts.add(product);
      await sharedPref.save(_cartKey, selectedProducts);
    } else {
      selectedProducts = Product.fromJsonList(data).toList();
      // Key by both id AND selectedVariant so the same product with different
      // variants occupies separate cart lines
      int index = selectedProducts.indexWhere(
          (p) => p.id == product.id && p.selectedVariant == product.selectedVariant);
      if (index == -1) {
        product.quantity ??= 1;
        selectedProducts.add(product);
      } else {
        selectedProducts[index].quantity = product.quantity;
      }
      await sharedPref.save(_cartKey, selectedProducts);
    }
  }

  @override
  Future<void> deleteItem(Product product) async {
    final data = await sharedPref.read(_cartKey);
    if (data == null) { return; }
    List<Product> selectedProducts = Product.fromJsonList(data).toList();
    selectedProducts.removeWhere(
        (p) => p.id == product.id && p.selectedVariant == product.selectedVariant);
    await sharedPref.save(_cartKey, selectedProducts);
  }

  @override
  Future<void> deleteShoppingBag() async {
    await sharedPref.remove(_cartKey);
  }

  @override
  Future<List<Product>> getProducts() async {
    final data = await sharedPref.read(_cartKey);
    if (data == null) {
      return [];
    }
    List<Product> selectedProducts = Product.fromJsonList(data).toList();
    return selectedProducts;
  }
  
  @override
  Future<double> getTotal() async {
    final data = await sharedPref.read(_cartKey);
    if (data == null) {
      return 0;
    }
    double total = 0;
    List<Product> selectedProducts = Product.fromJsonList(data).toList();
    selectedProducts.forEach((product) {
      total = total + (product.quantity! * product.effectivePrice);
    });
    return total;
  }


}