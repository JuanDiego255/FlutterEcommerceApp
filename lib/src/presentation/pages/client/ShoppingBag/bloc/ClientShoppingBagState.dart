import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:equatable/equatable.dart';

class ClientShoppingBagState extends Equatable {

  final List<Product> products;
  final double total;

  ClientShoppingBagState({
    this.products = const [],
    this.total = 0
  });

  ClientShoppingBagState copyWith({
    List<Product>? products,
    double? total
  }) {
    return ClientShoppingBagState(
      products: products ?? this.products,
      total: total ?? this.total
    );
  }

  @override
  List<Object?> get props => [products, total];
}