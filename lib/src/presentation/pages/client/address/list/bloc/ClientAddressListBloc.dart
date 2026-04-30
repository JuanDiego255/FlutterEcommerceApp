import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/AddressUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/OrdersUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientAddressListBloc
    extends Bloc<ClientAddressListEvent, ClientAddressListState> {

  final AddressUseCases addressUseCases;
  final AuthUseCases authUseCases;
  final ShoppingBagUseCases shoppingBagUseCases;
  final OrdersUseCases ordersUseCases;

  ClientAddressListBloc(
    this.addressUseCases,
    this.authUseCases,
    this.shoppingBagUseCases,
    this.ordersUseCases,
  ) : super(const ClientAddressListState()) {
    on<GetUserAddress>(_onGetUserAddress);
    on<ChangeRadioValue>(_onChangeRadioValue);
    on<SetAddressSession>(_onSetAddressSession);
    on<DeleteAddress>(_onDeleteAddress);
    on<OnPaymentSubmit>(_onPaymentSubmit);
    on<OnPaymentStripeSubmit>(_onPaymentStripeSubmit);
    on<OnConfirmOrder>(_onConfirmOrder);
  }

  Future<void> _onGetUserAddress(
      GetUserAddress event, Emitter<ClientAddressListState> emit) async {
    final AuthResponse? authResponse = await authUseCases.getUserSession.run();
    if (authResponse == null) return;
    emit(state.copyWith(response: Loading()));
    final Resource response =
        await addressUseCases.getUserAddress.run(authResponse.user.id!);
    emit(state.copyWith(response: response));
  }

  Future<void> _onChangeRadioValue(
      ChangeRadioValue event, Emitter<ClientAddressListState> emit) async {
    emit(state.copyWith(radioValue: event.radioValue));
    await addressUseCases.saveAddressInSession.run(event.address);
  }

  Future<void> _onSetAddressSession(
      SetAddressSession event, Emitter<ClientAddressListState> emit) async {
    final Address? addressSession =
        await addressUseCases.getAddressSession.run();
    if (addressSession != null) {
      final index = event.addressList
          .indexWhere((address) => address.id == addressSession.id);
      if (index != -1) {
        emit(state.copyWith(radioValue: index));
      }
    }
  }

  Future<void> _onDeleteAddress(
      DeleteAddress event, Emitter<ClientAddressListState> emit) async {
    emit(state.copyWith(response: Loading()));
    final Resource response = await addressUseCases.delete.run(event.id);
    emit(state.copyWith(response: response));
    final Address? addressSession =
        await addressUseCases.getAddressSession.run();
    if (addressSession != null && addressSession.id == event.id) {
      await addressUseCases.deleteFromSession.run();
      emit(state.copyWith(radioValue: null));
    }
  }

  Future<void> _onConfirmOrder(
      OnConfirmOrder event, Emitter<ClientAddressListState> emit) async {
    final Address? address = await addressUseCases.getAddressSession.run();
    if (address == null) {
      emit(state.copyWith(
          response: const Error('Seleccioná una dirección de entrega')));
      return;
    }

    final List<Product> products = await shoppingBagUseCases.getProducts.run();
    if (products.isEmpty) {
      emit(state.copyWith(
          response: const Error('El carrito está vacío')));
      return;
    }

    emit(state.copyWith(isCreatingOrder: true));
    final Resource response =
        await ordersUseCases.createOrder.run(address, products);
    emit(state.copyWith(isCreatingOrder: false));

    if (response is Success) {
      // Clear the shopping bag after successful order
      for (final p in products) {
        await shoppingBagUseCases.deleteItem.run(p);
      }
      emit(state.copyWith(response: response));
    } else {
      emit(state.copyWith(response: response));
    }
  }

  // Legacy handlers kept to avoid orphaned registrations
  Future<void> _onPaymentSubmit(
      OnPaymentSubmit event, Emitter<ClientAddressListState> emit) async {}

  Future<void> _onPaymentStripeSubmit(
      OnPaymentStripeSubmit event, Emitter<ClientAddressListState> emit) async {}
}
