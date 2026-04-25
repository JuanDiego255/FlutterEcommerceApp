import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';

abstract class CatalogProductsState {}

class CatalogProductsInitial extends CatalogProductsState {}

class CatalogProductsLoading extends CatalogProductsState {}

class CatalogProductsLoaded extends CatalogProductsState {
  final List<CatalogProduct> products;
  final bool hasMore;
  final int page;
  final int categoryId;
  final String search;
  final List<String> attrValues;

  CatalogProductsLoaded({
    required this.products,
    required this.hasMore,
    required this.page,
    required this.categoryId,
    required this.search,
    this.attrValues = const [],
  });
}

class CatalogProductsLoadingMore extends CatalogProductsState {
  final List<CatalogProduct> products;
  final int page;
  final int categoryId;
  final String search;
  final List<String> attrValues;

  CatalogProductsLoadingMore({
    required this.products,
    required this.page,
    required this.categoryId,
    required this.search,
    this.attrValues = const [],
  });
}

class CatalogProductsError extends CatalogProductsState {
  final String message;
  CatalogProductsError(this.message);
}
