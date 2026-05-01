import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/LoginContent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/bloc/LoginState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  LoginBloc? _bloc;

  @override
  void initState() { // EJECUTA UNA SOLA VEZ CUANDO CARGA LA PANTALLA
    super.initState();
    // WidgetsBinding.instance?.addPostFrameCallback((timeStamp) { 
    //   _loginBlocCubit?.dispose();
    // });
  }

  @override
  Widget build(BuildContext context) {

    _bloc = BlocProvider.of<LoginBloc>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            final responseState = state.response;
            if (responseState is Error) {
              Fluttertoast.showToast(
                msg: responseState.message,
                toastLength: Toast.LENGTH_LONG
              );
            }
            else if (responseState is Success) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final authResponse = responseState.data as AuthResponse;
                // Save session before navigating to avoid race condition where
                // the next page reads SharedPrefs before the Bloc event runs.
                await locator<AuthUseCases>().saveUserSession.run(authResponse);
                if (!context.mounted) return;
                final roles = authResponse.user.roles ?? [];
                final String nextRoute;
                if (roles.length == 1) {
                  nextRoute = roles.first.route;
                } else if (roles.isEmpty) {
                  nextRoute = 'catalog/home';
                } else {
                  nextRoute = 'roles';
                }
                Navigator.pushNamedAndRemoveUntil(context, nextRoute, (route) => false);
              });
            }
          },
          child: BlocBuilder<LoginBloc, LoginState>(
            buildWhen: (prev, curr) => prev.response != curr.response,
            builder: (context, state) {
              final responseState = state.response;
              if (responseState is Loading) {
                return Stack(
                  children: [
                    LoginContent(_bloc, state),
                    const Center(child: CircularProgressIndicator())
                  ],
                );
              }
              return LoginContent(_bloc, state);
            }
          )
        ),
      )
    );
  }

}