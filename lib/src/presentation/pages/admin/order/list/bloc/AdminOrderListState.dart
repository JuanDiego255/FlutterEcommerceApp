import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class AdminOrderListState extends Equatable {

  final Resource? response;

  const AdminOrderListState({
    this.response
  });

  AdminOrderListState copyWith({
    Resource? response
  }) {
    return AdminOrderListState(response: response);
  }

  @override
  // TODO: implement props
  List<Object?> get props => [response];

}