import 'package:ecommerce_flutter/src/domain/useCases/categories/CategoriesUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/category/list/bloc/ClientCategoryListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/category/list/bloc/ClientCategoryListState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientCategoryListBloc extends Bloc<ClientCategoryListEvent, ClientCategoryListState> {

  CategoriesUseCases categoriesUseCases;

  ClientCategoryListBloc(this.categoriesUseCases): super(ClientCategoryListState()) {
    on<GetCategories>(_onGetCategories); 
  } 

  Future<void> _onGetCategories(GetCategories event, Emitter<ClientCategoryListState> emit) async {
    emit(
      state.copyWith(
        response: Loading()
      )
    );
    Resource response = await categoriesUseCases.getCategories.run();
    emit(
      state.copyWith(
        response: response
      )
    );
  }

}