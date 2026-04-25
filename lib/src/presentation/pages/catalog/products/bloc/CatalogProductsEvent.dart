abstract class CatalogProductsEvent {}

class CatalogProductsLoad extends CatalogProductsEvent {
  final int categoryId;
  final String search;
  CatalogProductsLoad({required this.categoryId, this.search = ''});
}

class CatalogProductsLoadMore extends CatalogProductsEvent {}
