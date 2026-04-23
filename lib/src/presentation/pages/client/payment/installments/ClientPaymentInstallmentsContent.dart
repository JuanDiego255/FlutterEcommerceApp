import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoInstallments.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/bloc/ClientPaymentInstallmentsBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/bloc/ClientPaymentInstallmentsEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/bloc/ClientPaymentInstallmentsState.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/DefaultButton.dart';
import 'package:flutter/material.dart';

class ClientPaymentInstallmentsContent extends StatelessWidget {

  ClientPaymentInstallmentsBloc? bloc;
  ClientPaymentInstallmentsState state;
  MercadoPagoInstallments mercadoPagoInstallments;
  MercadoPagoCardTokenResponse mercadoPagoCardTokenResponse;

  ClientPaymentInstallmentsContent(this.bloc, this.state, this.mercadoPagoInstallments, this.mercadoPagoCardTokenResponse);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textInstallments(),
          _dropdownInstallments(),
          Spacer(),
          _buttonPay()
        ],
      ),
    );
  }
  
  Widget _buttonPay() {
    return Container(
      child: DefaultButton(
        text: 'PAGAR', 
        onPressed: () {
          bloc?.add(FormSubmit(
            mercadoPagoCardTokenResponse: mercadoPagoCardTokenResponse, 
            installments: mercadoPagoInstallments
          )
          );
        }
      ),
    );
  }

  Widget _textInstallments() {
    return Text(
      'Elije el numero de coutas',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 19
      ),
    );
  }

  Widget _dropdownInstallments() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: DropdownButton(
        hint: Text(
          'Numero de Coutas',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14
          ),
        ),
        value: state.installment,
        items: _dropDownItems(), 
        onChanged: (value) {
          bloc?.add(InstallmentChanged(installment: value!));
        }
      ),
    );
  }

  List<DropdownMenuItem<String>> _dropDownItems() {
    List<DropdownMenuItem<String>> list = [];
    mercadoPagoInstallments.payerCosts.forEach((installment) { 
      list.add(
        DropdownMenuItem(
          child: Container(
            margin: EdgeInsets.only(top: 7),
            child: Text(installment.recommendedMessage),
          ),
          value: installment.installments.toString(),
        )
      );
    });
    return list;
  }
}