import 'package:equatable/equatable.dart';

abstract class AdminOrderDetailEvent extends Equatable {

  const AdminOrderDetailEvent();

  @override
  List<Object?> get props => [];
}

class UpdateStatusOrder extends AdminOrderDetailEvent {
  final int id;
  const UpdateStatusOrder({required this.id});
  @override
  List<Object?> get props => [id];
}