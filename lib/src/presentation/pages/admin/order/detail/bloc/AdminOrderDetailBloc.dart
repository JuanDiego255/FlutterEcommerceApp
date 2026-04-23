import 'package:ecommerce_flutter/src/domain/useCases/orders/OrdersUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/bloc/AdminOrderDetailEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/bloc/AdminOrderDetailState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminOrderDetailBloc extends Bloc<AdminOrderDetailEvent, AdminOrderDetailState> {

  OrdersUseCases ordersUseCases;

  AdminOrderDetailBloc(this.ordersUseCases): super(AdminOrderDetailState()) {
    on<UpdateStatusOrder>(_onUpdateStatusOrder);
  } 

  Future<void> _onUpdateStatusOrder(UpdateStatusOrder event, Emitter<AdminOrderDetailState> emit) async {
    emit(
      state.copyWith(
        response: Loading()
      )
    );
    Resource response = await ordersUseCases.updateStatus.run(event.id);
    emit(
      state.copyWith(
        response: response
      )
    );
  }

}