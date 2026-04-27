import 'dart:convert';
import 'package:ecommerce_flutter/src/data/api/ApiConfig.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenBody.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoCardTokenResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoIdentificationType.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoInstallments.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentBody.dart';
import 'package:ecommerce_flutter/src/domain/models/MercadoPagoPaymentResponse.dart';
import 'package:ecommerce_flutter/src/domain/utils/ListToString.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

class MercadoPagoService {

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': SecureStorageService.authToken,
  };

  Future<Resource<List<MercadoPagoIdentificationType>>> getIdentificationTypes() async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/mercadopago/identification_types');
      final response = await http.get(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(MercadoPagoIdentificationType.fromJsonList(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<MercadoPagoCardTokenResponse>> createCardToken(MercadoPagoCardTokenBody body) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/mercadopago/card_token');
      final response = await http.post(url, headers: _headers, body: json.encode(body.toJson()));
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(MercadoPagoCardTokenResponse.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<MercadoPagoPaymentResponse>> createPayment(MercadoPagoPaymentBody body) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/mercadopago/payments');
      final response = await http.post(url, headers: _headers, body: json.encode(body.toJson()));
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(MercadoPagoPaymentResponse.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Resource<MercadoPagoInstallments>> getInstallments(String firstSixDigits, String amount) async {
    try {
      final url = Uri.https(ApiConfig.API_ECOMMERCE, '/api/mercadopago/installments/$firstSixDigits/$amount');
      final response = await http.get(url, headers: _headers);
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(MercadoPagoInstallments.fromJson(data));
      }
      return Error(listToString(data['message']));
    } catch (e) {
      return Error(e.toString());
    }
  }
}
