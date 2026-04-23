import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenBody.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoIdentificationType.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoInstallments.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentBody.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentResponse.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

abstract class MercadoPagoRepository {

  Future<Resource<List<MercadoPagoIdentificationType>>> getIdentificationTypes();
  Future<Resource<MercadoPagoCardTokenResponse>> createCardToken(MercadoPagoCardTokenBody mercadoPagoCardTokenBody);
  Future<Resource<MercadoPagoInstallments>> getInstallments(String firstSixDigits, String amount);
  Future<Resource<MercadoPagoPaymentResponse>> createPayment(MercadoPagoPaymentBody mercadoPagoPaymentBody);

}