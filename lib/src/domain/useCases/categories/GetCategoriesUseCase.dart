import 'package:ecommerce_flutter/src/domain/repository/CategoriesRepository.dart';

class GetCategoriesUseCase {

  CategoriesRepository categoriesRepository;

  GetCategoriesUseCase(this.categoriesRepository);

  run() => categoriesRepository.getCategories();

}