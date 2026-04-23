import 'dart:io';

import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CategoriesService.dart';
import 'package:ecommerce_flutter/src/domain/models/Category.dart';
import 'package:ecommerce_flutter/src/domain/repository/CategoriesRepository.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  
  CategoriesService categoriesService;

  CategoriesRepositoryImpl(this.categoriesService);

  @override
  Future<Resource<Category>> create(Category category, File file) {
    return categoriesService.create(category, file);
  }
  
  @override
  Future<Resource<List<Category>>> getCategories() {
    return categoriesService.getCategories();
  }
  
  @override
  Future<Resource<Category>> update(int id, Category category, File? file) {
    if (file == null) {
      return categoriesService.update(id, category);  
    }
    else {
      return categoriesService.updateImage(id, category, file);
    }
  }
  
  @override
  Future<Resource<bool>> delete(int id) {
    return categoriesService.delete(id);
  }

}