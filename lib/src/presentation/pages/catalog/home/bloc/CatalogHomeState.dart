import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogHomeData.dart';

abstract class CatalogHomeState {}

class CatalogHomeInitial extends CatalogHomeState {}

class CatalogHomeLoading extends CatalogHomeState {}

class CatalogHomeLoaded extends CatalogHomeState {
  final CatalogHomeData data;
  CatalogHomeLoaded(this.data);
}

class CatalogHomeError extends CatalogHomeState {
  final String message;
  CatalogHomeError(this.message);
}
