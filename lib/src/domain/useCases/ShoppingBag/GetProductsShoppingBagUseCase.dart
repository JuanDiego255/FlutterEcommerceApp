import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/repository/ShoppingBagRepository.dart';

class GetProductsShoppingBagUseCase {

  ShoppingBagRepository shoppingBagRepository;

  GetProductsShoppingBagUseCase(this.shoppingBagRepository);

  run() => shoppingBagRepository.getProducts();

}