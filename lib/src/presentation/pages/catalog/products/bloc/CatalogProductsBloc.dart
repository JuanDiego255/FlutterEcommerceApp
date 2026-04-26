import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'CatalogProductsEvent.dart';
import 'CatalogProductsState.dart';

class CatalogProductsBloc extends Bloc<CatalogProductsEvent, CatalogProductsState> {
  final CatalogService _service;

  CatalogProductsBloc(this._service) : super(CatalogProductsInitial()) {
    on<CatalogProductsLoad>(_onLoad);
    on<CatalogProductsLoadMore>(_onLoadMore);
  }

  Future<void> _onLoad(CatalogProductsLoad event, Emitter<CatalogProductsState> emit) async {
    emit(CatalogProductsLoading());
    // categoryId == 0 signals a global search across all categories
    final result = event.categoryId == 0
        ? await _service.globalSearch(event.search, page: 1, perPage: 20)
        : await _service.getProductsByCategory(
            event.categoryId,
            page: 1,
            search: event.search,
            attrValues: event.attrValues,
          );
    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final items = _parseProducts(data);
      final lastPage = _lastPage(data);
      emit(CatalogProductsLoaded(
        products: items,
        hasMore: lastPage > 1,
        page: 1,
        categoryId: event.categoryId,
        search: event.search,
        attrValues: event.attrValues,
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(CatalogProductsError(result.message));
    }
  }

  Future<void> _onLoadMore(CatalogProductsLoadMore event, Emitter<CatalogProductsState> emit) async {
    final current = state;
    if (current is! CatalogProductsLoaded || !current.hasMore) return;

    final nextPage = current.page + 1;
    emit(CatalogProductsLoadingMore(
      products: current.products,
      page: current.page,
      categoryId: current.categoryId,
      search: current.search,
      attrValues: current.attrValues,
    ));

    final result = current.categoryId == 0
        ? await _service.globalSearch(current.search, page: nextPage, perPage: 20)
        : await _service.getProductsByCategory(
            current.categoryId,
            page: nextPage,
            search: current.search,
            attrValues: current.attrValues,
          );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final newItems = _parseProducts(data);
      final lastPage = _lastPage(data);
      emit(CatalogProductsLoaded(
        products: [...current.products, ...newItems],
        hasMore: nextPage < lastPage,
        page: nextPage,
        categoryId: current.categoryId,
        search: current.search,
        attrValues: current.attrValues,
      ));
    } else {
      emit(CatalogProductsLoaded(
        products: current.products,
        hasMore: false,
        page: current.page,
        categoryId: current.categoryId,
        search: current.search,
        attrValues: current.attrValues,
      ));
    }
  }

  List<CatalogProduct> _parseProducts(Map<String, dynamic> data) {
    final list = data['data'] as List<dynamic>? ?? [];
    return CatalogProduct.fromJsonList(list);
  }

  int _lastPage(Map<String, dynamic> data) {
    // API returns 'pagination' key (HomeDataController / globalSearch)
    final pag = data['pagination'] as Map<String, dynamic>?;
    if (pag != null) return (pag['last_page'] as int?) ?? 1;
    // Fall back to 'meta' key if ever used
    final meta = data['meta'] as Map<String, dynamic>?;
    return (meta?['last_page'] as int?) ?? 1;
  }
}
