import 'package:equatable/equatable.dart';

abstract class ClientPaymentFormEvent extends Equatable {
  const ClientPaymentFormEvent();
  @override
  List<Object?> get props => [];
}

class ClientPaymentFormInitEvent extends ClientPaymentFormEvent {
  const ClientPaymentFormInitEvent();
}

class CreditCardChanged extends ClientPaymentFormEvent {

  final String cardNumber;
  final String expireDate;
  final String cardHolderName;
  final String cvvCode;
  final bool isCvvFocused;

   const CreditCardChanged({
    required this.cardNumber,
    required this.expireDate,
    required this.cardHolderName,
    required this.cvvCode,
    required this.isCvvFocused,
  });

  @override
  List<Object?> get props => [cardNumber, expireDate, cardHolderName, cvvCode, isCvvFocused];

}

class IdentificationTypeChanged extends ClientPaymentFormEvent {
  final String identificationType;
  const IdentificationTypeChanged({required this.identificationType});
  @override
  List<Object?> get props => [identificationType];
}

class IdentificationNumberChanged extends ClientPaymentFormEvent {
  final String identificationNumber;
  const IdentificationNumberChanged({required this.identificationNumber});
  @override
  List<Object?> get props => [identificationNumber];
}

class FormSubmit extends ClientPaymentFormEvent {
  const FormSubmit();
}