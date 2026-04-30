import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:equatable/equatable.dart';

abstract class ClientAddressListEvent extends Equatable {
  const ClientAddressListEvent();
  @override
  List<Object?> get props => [];
}

class GetUserAddress extends ClientAddressListEvent {
  const GetUserAddress();
}

class ChangeRadioValue extends ClientAddressListEvent {
  final int radioValue;
  final Address address;

  ChangeRadioValue({required this.radioValue, required this.address});

  @override
  // TODO: implement props
  List<Object?> get props => [radioValue, address];
}

class SetAddressSession extends ClientAddressListEvent {
  final List<Address> addressList;

  const SetAddressSession({ required this.addressList });

  @override
  // TODO: implement props
  List<Object?> get props => [addressList];
}

class DeleteAddress extends ClientAddressListEvent {
  final int id;
  const DeleteAddress({required this.id});
  @override
  List<Object?> get props => [id];
}

class OnPaymentSubmit extends ClientAddressListEvent {
  const OnPaymentSubmit();
}

class OnPaymentStripeSubmit extends ClientAddressListEvent {
  const OnPaymentStripeSubmit();
}

class OnConfirmOrder extends ClientAddressListEvent {
  const OnConfirmOrder();
}