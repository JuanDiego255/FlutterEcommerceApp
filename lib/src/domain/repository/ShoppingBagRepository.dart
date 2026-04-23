import 'package:ecommerce_flutter/src/domain/models/Product.dart';

abstract class ShoppingBagRepository {

  Future<void> add(Product product);
  Future<List<Product>> getProducts();
  Future<void> deleteItem(Product product);
  Future<void> deleteShoppingBag();
  Future<double> getTotal();

}