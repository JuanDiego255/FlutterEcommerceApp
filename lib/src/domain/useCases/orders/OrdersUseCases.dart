import 'package:ecommerce_flutter/src/domain/useCases/orders/GetOrdersByClientUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/GetOrdersUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/UpdateStatusOrderUseCase.dart';

class OrdersUseCases {

  GetOrdersUseCase getOrders;
  GetOrdersByClientUseCase getOrdersByClient;
  UpdateStatusOrderUseCase updateStatus;

  OrdersUseCases({
    required this.getOrders,
    required this.getOrdersByClient,
    required this.updateStatus,
  });

}