import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoInstallments.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentResponse.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/ClientPaymentInstallmentsContent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/bloc/ClientPaymentInstallmentsBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/bloc/ClientPaymentInstallmentsEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/bloc/ClientPaymentInstallmentsState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ClientPaymentInstallmentsPage extends StatefulWidget {
  const ClientPaymentInstallmentsPage({super.key});

  @override
  State<ClientPaymentInstallmentsPage> createState() =>
      _ClientPaymentInstallmentsPageState();
}

class _ClientPaymentInstallmentsPageState
    extends State<ClientPaymentInstallmentsPage> {
  ClientPaymentInstallmentsBloc? _bloc;
  MercadoPagoCardTokenResponse? mercadoPagoCardTokenResponse;
  String? amount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _bloc?.add(GetInstallments(
          firstSixDigits: mercadoPagoCardTokenResponse!.firstSixDigits,
          amount: amount!));
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    mercadoPagoCardTokenResponse = arguments['mercadoPagoCardTokenResponse'] as MercadoPagoCardTokenResponse;
    amount = arguments['amount'] as String;
    _bloc = BlocProvider.of<ClientPaymentInstallmentsBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Ultimo paso'),
        backgroundColor: Colors.grey[200],
      ),
      body: BlocListener<ClientPaymentInstallmentsBloc, ClientPaymentInstallmentsState>(
        listener: (context, state) {
          final responsePayment = state.responsePayment;
          if (responsePayment is Success) {
            MercadoPagoPaymentResponse mercadoPagoPaymentResponse = responsePayment.data as MercadoPagoPaymentResponse; 
            Navigator.pushNamedAndRemoveUntil(
              context, 
              'client/payment/status', 
              (route) => false,
              arguments: mercadoPagoPaymentResponse
            );
          }
          else if (responsePayment is Error) {
            Fluttertoast.showToast(msg: responsePayment.message, toastLength: Toast.LENGTH_LONG);
          }
        },
        child: BlocBuilder<ClientPaymentInstallmentsBloc,ClientPaymentInstallmentsState>(
          builder: (context, state) {
            final responseState = state.responseInstallments;
            if (responseState is Loading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (responseState is Success) {
              MercadoPagoInstallments installments = responseState.data as MercadoPagoInstallments;
              return ClientPaymentInstallmentsContent(_bloc, state, installments, mercadoPagoCardTokenResponse!);
            }
            return Container();
          },
        ),
      ),
    );
  }
}
