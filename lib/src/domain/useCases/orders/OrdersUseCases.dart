import 'package:ecommerce_flutter/src/domain/useCases/orders/CreateOrderUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/GetOrdersByClientUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/GetOrdersUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/UpdateStatusOrderUseCase.dart';

class OrdersUseCases {

  GetOrdersUseCase getOrders;
  GetOrdersByClientUseCase getOrdersByClient;
  UpdateStatusOrderUseCase updateStatus;
  CreateOrderUseCase createOrder;

  OrdersUseCases({
    required this.getOrders,
    required this.getOrdersByClient,
    required this.updateStatus,
    required this.createOrder,
  });
}