import 'package:ecommerce_flutter/src/domain/repository/ProductsRepository.dart';

class GetProductsByCategoryUseCase {

  ProductsRepository productsRepository;

  GetProductsByCategoryUseCase(this.productsRepository);

  run(int idCategory) => productsRepository.getProductsByCategory(idCategory);

}