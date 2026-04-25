import 'dart:convert';

import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentBody.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/AddressUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/CategoriesUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/bloc/ClientAddressListState.dart';
import 'package:http/http.dart' as http;


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientAddressListBloc extends Bloc<ClientAddressListEvent, ClientAddressListState> {

  AddressUseCases addressUseCases;
  AuthUseCases authUseCases;
  ShoppingBagUseCases shoppingBagUseCases;

  ClientAddressListBloc(this.addressUseCases, this.authUseCases, this.shoppingBagUseCases): super(ClientAddressListState()) {
    on<GetUserAddress>(_onGetUserAddress); 
    on<ChangeRadioValue>(_onChangeRadioValue); 
    on<SetAddressSession>(_onSetAddressSession); 
    on<DeleteAddress>(_onDeleteAddress); 
    on<OnPaymentSubmit>(_onPaymentSubmit);
    on<OnPaymentStripeSubmit>(_onPaymentStripeSubmit);
  } 

  Future<void> _onGetUserAddress(GetUserAddress event, Emitter<ClientAddressListState> emit) async {
    AuthResponse? authResponse = await authUseCases.getUserSession.run();
    if (authResponse != null) {
      emit(
        state.copyWith(
          response: Loading()
        )
      );
      Resource response = await addressUseCases.getUserAddress.run(authResponse.user.id!);
      emit(
        state.copyWith(
          response: response
        )
      );
    }   
  }

  Future<void> _onChangeRadioValue(ChangeRadioValue event, Emitter<ClientAddressListState> emit) async {
    emit(
      state.copyWith(radioValue: event.radioValue)
    );
    await addressUseCases.saveAddressInSession.run(event.address);    
  }

  Future<void> _onSetAddressSession(SetAddressSession event, Emitter<ClientAddressListState> emit) async {
    Address? addressSession = await addressUseCases.getAddressSession.run();
    if (addressSession != null) {
      int index = event.addressList.indexWhere((address) => address.id == addressSession.id);
      if (index != -1) { // YA HEMOS SELECCIONADO UNA DIRECCION Y ESTA GUARDADA EN SESION
        emit(state.copyWith(radioValue: index));
      }
    }
  }

  Future<void> _onPaymentStripeSubmit(OnPaymentStripeSubmit event, Emitter<ClientAddressListState> emit) async {
    final response = await http.post(
      Uri.parse('https://payment_stripe/create'),
    );
    print('RESPONSE STATUS: ${response.statusCode}');
    print('RESPONSE BODY: ${response.body}');
    if (response.statusCode == 200) {
      final url = jsonDecode(response.body)['checkout_url'];
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      else {
        throw 'No se puede abrir la URL de Stripe $url';
      }
    }
    else {
      throw 'Error en la sesion de pago';
    }
  }

  Future<void> _onDeleteAddress(DeleteAddress event, Emitter<ClientAddressListState> emit) async {
    emit(
      state.copyWith(
        response: Loading()
      )
    );
    Resource response = await addressUseCases.delete.run(event.id);
    emit(
      state.copyWith(
        response: response
      )
    );
    Address? addressSession = await addressUseCases.getAddressSession.run();
    if (addressSession != null) {
      if (addressSession.id == event.id) {
        await addressUseCases.deleteFromSession.run();
        emit(state.copyWith(radioValue: null));
      }
    }
    
  }

  Future<void> _onPaymentSubmit(OnPaymentSubmit event, Emitter<ClientAddressListState> emit) async {
    double totalToPay = await shoppingBagUseCases.getTotal.run();
    AuthResponse authResponse = await authUseCases.getUserSession.run();
    Address address = await addressUseCases.getAddressSession.run();
    List<Product> products = await shoppingBagUseCases.getProducts.run();

    final url = Uri.parse('https://payment/create');
    try {
      final orderBody = OrderBody(
        idUser: authResponse.user.id!, 
        idAddress: address.id!, 
        products: products
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode(orderBody.toJson())
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final initPoint = data['init_point'];
        final uri = Uri.parse(initPoint);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        else {
          throw 'No se pudo abrir el enlace de pago';
        }
      }
      else {
        print('Error al crear la preferencia de pagos: ${response.body}');
      }
    } catch (e) {
      print('Error al abrir la ruta de pagos: $e');
    }
  }

  

}