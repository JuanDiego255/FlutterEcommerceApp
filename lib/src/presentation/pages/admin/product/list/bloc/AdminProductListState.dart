import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class AdminProductListState extends Equatable {

  final Resource? response;

  const AdminProductListState({this.response});

  AdminProductListState copyWith({
    Resource? response
  }) {
    return AdminProductListState(response: response);
  }

  @override
  // TODO: implement props
  List<Object?> get props => [response];

}