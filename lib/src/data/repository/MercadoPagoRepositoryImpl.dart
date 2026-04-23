import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MercadoPagoService.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenBody.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoIdentificationType.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoInstallments.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentBody.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentResponse.dart';
import 'package:ecommerce_flutter/src/domain/repository/MercadoPagoRepository.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

class MercadoPagoRepositoryImpl implements MercadoPagoRepository {
  
  MercadoPagoService mercadoPagoService;

  MercadoPagoRepositoryImpl(this.mercadoPagoService);

  @override
  Future<Resource<List<MercadoPagoIdentificationType>>> getIdentificationTypes() {
    return mercadoPagoService.getIdentificationTypes();
  }

  @override
  Future<Resource<MercadoPagoCardTokenResponse>> createCardToken(MercadoPagoCardTokenBody mercadoPagoCardTokenBody) {
    return mercadoPagoService.createCardToken(mercadoPagoCardTokenBody);
  }

  @override
  Future<Resource<MercadoPagoInstallments>> getInstallments(String firstSixDigits, String amount) {
    return mercadoPagoService.getInstallments(firstSixDigits, amount);
  }

  @override
  Future<Resource<MercadoPagoPaymentResponse>> createPayment(MercadoPagoPaymentBody mercadoPagoPaymentBody) {
    return mercadoPagoService.createPayment(mercadoPagoPaymentBody);
  }

}