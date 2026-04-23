import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/bloc/RolesEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/bloc/RolesState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolesBloc extends Bloc<RolesEvent, RolesState> {

  AuthUseCases authUseCases;

  RolesBloc(this.authUseCases): super(RolesState()) {
    on<GetRolesList>(_onGetRolesList);
  }

  Future<void> _onGetRolesList(GetRolesList event, Emitter<RolesState> emit) async {
    AuthResponse? authResponse = await authUseCases.getUserSession.run();
    emit(
      state.copyWith(
        roles: authResponse?.user.roles
      )
    );
  }

}