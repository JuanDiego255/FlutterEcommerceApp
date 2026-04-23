import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoInstallments.dart';
import 'package:equatable/equatable.dart';

abstract class ClientPaymentInstallmentsEvent extends Equatable {
  const ClientPaymentInstallmentsEvent();
  @override
  List<Object?> get props => [];
}

class GetInstallments extends ClientPaymentInstallmentsEvent {

  final String firstSixDigits;
  final String amount;

  const GetInstallments({ required this.firstSixDigits, required this.amount });

  @override
  List<Object?> get props => [firstSixDigits, amount];

}

class InstallmentChanged extends ClientPaymentInstallmentsEvent {
  final String installment;
  const InstallmentChanged({required this.installment});
  @override
  List<Object?> get props => [installment];
}

class FormSubmit extends ClientPaymentInstallmentsEvent {
  final MercadoPagoCardTokenResponse mercadoPagoCardTokenResponse;
  final MercadoPagoInstallments installments;
  const FormSubmit({ required this.mercadoPagoCardTokenResponse, required this.installments });
  @override
  List<Object?> get props => [mercadoPagoCardTokenResponse, installments];
}