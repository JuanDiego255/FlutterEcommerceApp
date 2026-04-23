import 'package:equatable/equatable.dart';

abstract class ClientOrderListEvent extends Equatable {
  const ClientOrderListEvent();
  @override
  List<Object?> get props => [];
}

class GetOrders extends ClientOrderListEvent {
  const GetOrders();
}