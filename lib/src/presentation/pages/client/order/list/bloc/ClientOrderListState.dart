import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class ClientOrderListState extends Equatable {

  final Resource? response;

  const ClientOrderListState({
    this.response
  });

  ClientOrderListState copyWith({
    Resource? response
  }) {
    return ClientOrderListState(response: response);
  }

  @override
  // TODO: implement props
  List<Object?> get props => [response];

}