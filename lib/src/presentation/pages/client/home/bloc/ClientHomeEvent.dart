import 'package:equatable/equatable.dart';

abstract class ClientHomeEvent extends Equatable {
  const ClientHomeEvent();
  @override
  List<Object?> get props => [];
}

class ChangeDrawerPage extends ClientHomeEvent {
  final int pageIndex;
  const ChangeDrawerPage({ required this.pageIndex });
  @override
  List<Object?> get props => [pageIndex];
}

class Logout extends ClientHomeEvent {
  const Logout();
}