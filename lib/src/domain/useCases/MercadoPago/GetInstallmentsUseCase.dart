import 'package:ecommerce_flutter/src/domain/repository/MercadoPagoRepository.dart';

class GetInstallmentsUseCase {

  MercadoPagoRepository mercadoPagoRepository;

  GetInstallmentsUseCase(this.mercadoPagoRepository);

  run(String firstSixDigits, String amount) => mercadoPagoRepository.getInstallments(firstSixDigits, amount);

}