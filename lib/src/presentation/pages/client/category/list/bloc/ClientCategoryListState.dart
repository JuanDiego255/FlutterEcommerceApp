import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class ClientCategoryListState extends Equatable {
  final Resource? response;

  const ClientCategoryListState({
    this.response
  });

  ClientCategoryListState copyWith({
    Resource? response
  }) {
    return ClientCategoryListState(response: response);
  }

  @override
  List<Object?> get props => [response];
}