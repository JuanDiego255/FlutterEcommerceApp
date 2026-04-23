import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentBody.dart';
import 'package:ecommerce_flutter/src/domain/repository/MercadoPagoRepository.dart';

class CreatePaymentUseCase {

  MercadoPagoRepository mercadoPagoRepository;

  CreatePaymentUseCase(this.mercadoPagoRepository);

  run(MercadoPagoPaymentBody mercadoPagoPaymentBody) => mercadoPagoRepository.createPayment(mercadoPagoPaymentBody);

}