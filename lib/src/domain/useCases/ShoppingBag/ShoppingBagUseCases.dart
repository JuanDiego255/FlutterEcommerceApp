import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/AddShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/DeleteItemShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/DeleteShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/GetProductsShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/GetTotalShoppingBagUseCase.dart';

class ShoppingBagUseCases {

  AddShoppingBagUseCase add;
  GetProductsShoppingBagUseCase getProducts;
  DeleteItemShoppinBagUseCase deleteItem;
  deleteShoppingBagUseCase deleteShoppingBag;
  GetTotalShoppingBagUseCase getTotal;

  ShoppingBagUseCases({
    required this.add,
    required this.getProducts,
    required this.deleteItem,
    required this.deleteShoppingBag,
    required this.getTotal,
  });

}