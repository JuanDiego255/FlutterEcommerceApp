abstract class CatalogProductsEvent {}

class CatalogProductsLoad extends CatalogProductsEvent {
  final int categoryId;
  final String search;
  final List<String> attrValues;
  CatalogProductsLoad({
    required this.categoryId,
    this.search = '',
    this.attrValues = const [],
  });
}

class CatalogProductsLoadMore extends CatalogProductsEvent {}
