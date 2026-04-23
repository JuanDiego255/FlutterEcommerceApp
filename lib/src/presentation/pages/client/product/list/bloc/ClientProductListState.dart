import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class ClientProductListState extends Equatable {

  final Resource? response;

  const ClientProductListState({this.response});

  ClientProductListState copyWith({
    Resource? response
  }) {
    return ClientProductListState(response: response);
  }

  @override
  // TODO: implement props
  List<Object?> get props => [response];

}