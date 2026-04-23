import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientHomeBloc extends Bloc<ClientHomeEvent, ClientHomeState> {

  AuthUseCases authUseCases;

  ClientHomeBloc(this.authUseCases): super(ClientHomeState()) {
    on<ChangeDrawerPage>(_onChangeDrawerPage);
    on<Logout>(_onLogout);
  }

  Future<void> _onChangeDrawerPage(ChangeDrawerPage event, Emitter<ClientHomeState> emit) async {
    emit(
      state.copyWith(
        pageIndex: event.pageIndex
      )
    );
  }

  Future<void> _onLogout(Logout event, Emitter<ClientHomeState> emit) async {
    await authUseCases.logout.run();
  }

}