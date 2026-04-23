import 'dart:io';

import 'package:ecommerce_flutter/src/data/dataSource/remote/services/ProductsService.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/repository/ProductsRepository.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  
  ProductsService productsService;

  ProductsRepositoryImpl(this.productsService);

  @override
  Future<Resource<Product>> create(Product product, List<File> files) {
    return productsService.create(product, files);
  }
  
  @override
  Future<Resource<List<Product>>> getProductsByCategory(int idCategory) {
    return productsService.getProductsByCategory(idCategory);
  }
  
  @override
  Future<Resource<Product>> update(int id, Product product, List<File>? files) {
    return productsService.update(id, product, files);
  }
  
  @override
  Future<Resource<bool>> delete(int id) {
    return productsService.delete(id);
  }

}