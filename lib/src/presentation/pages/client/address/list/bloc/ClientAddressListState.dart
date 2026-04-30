import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:equatable/equatable.dart';

class ClientAddressListState extends Equatable {
  final int? radioValue;
  final Resource? response;
  final bool isCreatingOrder;

  const ClientAddressListState({
    this.response,
    this.radioValue,
    this.isCreatingOrder = false,
  });

  ClientAddressListState copyWith({
    Resource? response,
    int? radioValue,
    bool? isCreatingOrder,
  }) {
    return ClientAddressListState(
      response: response ?? this.response,
      radioValue: radioValue ?? this.radioValue,
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
    );
  }

  @override
  List<Object?> get props => [response, radioValue, isCreatingOrder];
}