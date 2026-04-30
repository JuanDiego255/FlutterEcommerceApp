import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/repository/OrdersRepository.dart';

class CreateOrderUseCase {

  OrdersRepository ordersRepository;

  CreateOrderUseCase(this.ordersRepository);

  run(Address address, List<Product> products) =>
      ordersRepository.createOrder(address, products);
}
