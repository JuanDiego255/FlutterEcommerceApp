import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

abstract class OrdersRepository {

  Future<Resource<List<Order>>> getOrders();
  Future<Resource<List<Order>>> getOrdersByClient(int idClient);
  Future<Resource<Order>> updateStatus(int id);

}