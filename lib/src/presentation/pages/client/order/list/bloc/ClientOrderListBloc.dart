import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/OrdersUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientOrderListBloc extends Bloc<ClientOrderListEvent, ClientOrderListState> {

  OrdersUseCases ordersUseCases;
  AuthUseCases authUseCases;

  ClientOrderListBloc(this.ordersUseCases, this.authUseCases): super(ClientOrderListState()) {
    on<GetOrders>(_onGetOrders);
  }

  Future<void> _onGetOrders(GetOrders event, Emitter<ClientOrderListState> emit) async {
    emit(state.copyWith(response: Loading()));
    final AuthResponse? authResponse = await authUseCases.getUserSession.run();
    if (authResponse == null) {
      emit(state.copyWith(response: const Error('Iniciá sesión para ver tus pedidos')));
      return;
    }
    final Resource response = await ordersUseCases.getOrdersByClient.run(authResponse.user.id!);
    emit(state.copyWith(response: response));
  }
}
