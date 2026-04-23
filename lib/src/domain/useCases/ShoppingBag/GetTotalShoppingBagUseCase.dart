import 'package:ecommerce_flutter/src/domain/repository/ShoppingBagRepository.dart';

class GetTotalShoppingBagUseCase {

  ShoppingBagRepository shoppingBagRepository;

  GetTotalShoppingBagUseCase(this.shoppingBagRepository);

  run() => shoppingBagRepository.getTotal();

}