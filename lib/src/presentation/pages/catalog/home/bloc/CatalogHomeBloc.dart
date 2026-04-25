import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'CatalogHomeEvent.dart';
import 'CatalogHomeState.dart';

class CatalogHomeBloc extends Bloc<CatalogHomeEvent, CatalogHomeState> {
  final CatalogService _service;

  CatalogHomeBloc(this._service) : super(CatalogHomeInitial()) {
    on<CatalogHomeLoad>(_onLoad);
  }

  Future<void> _onLoad(CatalogHomeLoad event, Emitter<CatalogHomeState> emit) async {
    emit(CatalogHomeLoading());
    final result = await _service.getHome();
    if (result is Success) {
      emit(CatalogHomeLoaded(result.data!));
    } else if (result is Error) {
      emit(CatalogHomeError(result.message ?? 'Error desconocido'));
    }
  }
}
