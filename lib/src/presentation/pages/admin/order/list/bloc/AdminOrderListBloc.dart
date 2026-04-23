import 'package:ecommerce_flutter/src/domain/useCases/orders/OrdersUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/bloc/AdminOrderListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/list/bloc/AdminOrderListState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminOrderListBloc extends Bloc<AdminOrderListEvent, AdminOrderListState> {

  OrdersUseCases ordersUseCases;

  AdminOrderListBloc(this.ordersUseCases): super(AdminOrderListState()) {
    on<GetOrders>(_onGetOrders);
  }

  Future<void> _onGetOrders(GetOrders event, Emitter<AdminOrderListState> emit) async {
    emit(
      state.copyWith(response: Loading())
    );
    Resource response = await ordersUseCases.getOrders.run();
    emit(
      state.copyWith(response: response)
    );
  }

}