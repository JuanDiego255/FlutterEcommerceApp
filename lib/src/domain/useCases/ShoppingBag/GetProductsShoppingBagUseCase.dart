import 'package:ecommerce_flutter/src/domain/repository/ShoppingBagRepository.dart';

class GetProductsShoppingBagUseCase {

  ShoppingBagRepository shoppingBagRepository;

  GetProductsShoppingBagUseCase(this.shoppingBagRepository);

  run() => shoppingBagRepository.getProducts();

}