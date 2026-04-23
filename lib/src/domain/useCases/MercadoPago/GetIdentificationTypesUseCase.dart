import 'package:ecommerce_flutter/src/domain/repository/MercadoPagoRepository.dart';

class GetIdentificationTypesUseCase {

  MercadoPagoRepository mercadoPagoRepository;

  GetIdentificationTypesUseCase(this.mercadoPagoRepository);

  run() => mercadoPagoRepository.getIdentificationTypes();

}