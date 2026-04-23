import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class ClientAddressListState extends Equatable {
  final int? radioValue;
  final Resource? response;

  const ClientAddressListState({
    this.response,
    this.radioValue
  });

  ClientAddressListState copyWith({
    Resource? response,
    int? radioValue
  }) {
    return ClientAddressListState(
      response: response ?? this.response,
      radioValue: radioValue ?? this.radioValue
    );
  }

  @override
  List<Object?> get props => [response, radioValue];
}