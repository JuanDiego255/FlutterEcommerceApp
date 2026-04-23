import 'package:equatable/equatable.dart';

abstract class AdminOrderListEvent extends Equatable {
  const AdminOrderListEvent();
  @override
  List<Object?> get props => [];
}

class GetOrders extends AdminOrderListEvent {
  const GetOrders();
}