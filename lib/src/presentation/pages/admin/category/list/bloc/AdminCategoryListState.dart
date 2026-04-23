import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class AdminCategoryListState extends Equatable {
  final Resource? response;

  const AdminCategoryListState({
    this.response
  });

  AdminCategoryListState copyWith({
    Resource? response
  }) {
    return AdminCategoryListState(response: response);
  }

  @override
  List<Object?> get props => [response];
}