import 'package:ecommerce_flutter/src/domain/useCases/categories/CreateCategoryUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/DeleteCategoryUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/GetCategoriesUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/UpdateCategoryUseCase.dart';

class CategoriesUseCases {

  CreateCategoryUseCase create;
  GetCategoriesUseCase getCategories;
  UpdateCategoryUseCase update;
  DeleteCategoryUseCase delete;

  CategoriesUseCases({
    required this.create,
    required this.getCategories,
    required this.update,
    required this.delete
  });

}