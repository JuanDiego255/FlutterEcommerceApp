import 'package:ecommerce_flutter/src/data/dataSource/remote/services/OrdersService.dart';
import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/repository/OrdersRepository.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

class OrdersRepositoryImpl implements OrdersRepository {

  OrdersService ordersService;

  OrdersRepositoryImpl(this.ordersService);

  @override
  Future<Resource<List<Order>>> getOrders() {
    return ordersService.getOrders();
  }

  @override
  Future<Resource<List<Order>>> getOrdersByClient(int idClient) {
    return ordersService.getOrdersByClient(idClient);
  }

  @override
  Future<Resource<Order>> updateStatus(int id) {
    return ordersService.updateStatus(id);
  }

  @override
  Future<Resource<Order>> createOrder(Address address, List<Product> products) {
    return ordersService.createOrder(address, products);
  }
}