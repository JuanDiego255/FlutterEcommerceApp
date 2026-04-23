import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenBody.dart';
import 'package:ecommerce_flutter/src/domain/repository/MercadoPagoRepository.dart';

class CreateCardTokenUseCase {

  MercadoPagoRepository mercadoPagoRepository;

  CreateCardTokenUseCase(this.mercadoPagoRepository);

  run(MercadoPagoCardTokenBody mercadoPagoCardTokenBody) => mercadoPagoRepository.createCardToken(mercadoPagoCardTokenBody);

}