import 'package:equatable/equatable.dart';

abstract class ClientProductListEvent extends Equatable {
  const ClientProductListEvent();
  @override
  List<Object?> get props => [];
} 

class GetProductsByCategory extends ClientProductListEvent {
  final int idCategory;

  const GetProductsByCategory({ required this.idCategory });

  @override
  List<Object?> get props => [idCategory];
}
