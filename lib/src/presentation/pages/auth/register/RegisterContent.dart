import 'package:ecommerce_flutter/src/presentation/pages/auth/register/bloc/RegisterBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/register/bloc/RegisterEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/register/bloc/RegisterState.dart';
import 'package:ecommerce_flutter/src/presentation/utils/BlocFormItem.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/DefaultButton.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/DefaultIconBack.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/DefaultTextField.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterContent extends StatelessWidget {

  final RegisterBloc? bloc;
  final RegisterState state;

  const RegisterContent(this.bloc, this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: state.formKey,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/img/london.jpg',
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
            color: Color.fromRGBO(0, 0, 0, 0.7),
            colorBlendMode: BlendMode.darken,
          ),
          
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.3),
              borderRadius: BorderRadius.all(Radius.circular(25))
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 100,
                  ),
                  Text(
                    'REGISTRO',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25, right: 25),
                    child: DefaultTextField(
                      label: 'Nombre', 
                      icon: Icons.person, 
                      onChanged: (text) {
                        bloc?.add(RegisterNameChanged(name: BlocFormItem(value: text)));
                      }
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25, right: 25),
                    child: DefaultTextField(
                      label: 'Apellido', 
                      icon: Icons.person_outline, 
                      onChanged: (text) {
                        bloc?.add(RegisterLastnameChanged(lastname: BlocFormItem(value: text)));
                      }
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25, right: 25),
                    child: DefaultTextField(
                      label: 'Email', 
                      icon: Icons.email, 
                      onChanged: (text) {
                        bloc?.add(RegisterEmailChanged(email: BlocFormItem(value: text)));
                      }
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25, right: 25),
                    child: DefaultTextField(
                      label: 'Telefono',
                      icon: Icons.phone, 
                      onChanged: (text) {
                        bloc?.add(RegisterPhoneChanged(phone: BlocFormItem(value: text)));
                      }
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25, right: 25),
                    child: DefaultTextField(
                      label: 'Contraseña', 
                      icon: Icons.lock, 
                      obscureText: true,
                      onChanged: (text) {
                        bloc?.add(RegisterPasswordChanged(password: BlocFormItem(value: text)));
                      }
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25, right: 25),
                    child: DefaultTextField(
                      label: 'Confirmar Contraseña', 
                      icon: Icons.lock_outline, 
                      obscureText: true,
                      onChanged: (text) {
                        bloc?.add(RegisterConfirmPasswordChanged(confirmPassword: BlocFormItem(value: text)));
                      }
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 25, right: 25, top: 15),
                    child: DefaultButton(
                      text: 'REGISTRARSE', 
                      color:  Colors.black,
                      onPressed: () {
                        if (state.formKey!.currentState!.validate()) {
                          bloc?.add(RegisterFormSubmit());
                        }
                        else {
                          Fluttertoast.showToast(
                            msg: 'El formulario no es valido',
                            toastLength: Toast.LENGTH_LONG
                          );
                        }
                      }
                    ),
                  )
                ],
              ),
            ),
          ),
          DefaultIconBack(
            left: 55,
            top: 140,
          )
        ],
      ),
    );
  }
}