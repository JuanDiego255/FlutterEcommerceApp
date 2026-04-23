import 'package:equatable/equatable.dart';

abstract class ClientCategoryListEvent extends Equatable {
  const ClientCategoryListEvent();
  @override
  List<Object?> get props => [];
}

class GetCategories extends ClientCategoryListEvent {
  const GetCategories();
}
