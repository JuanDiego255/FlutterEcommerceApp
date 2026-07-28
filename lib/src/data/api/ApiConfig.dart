import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

class ApiConfig {
  static String get BASE_URL => TenantSession.host;
  static String get API_ECOMMERCE => TenantSession.host;

  /// Dominio central de la plataforma (sin tenancy). Único host que no
  /// depende del tenant seleccionado: sirve el directorio de tiendas
  /// habilitadas para la app (`GET /api/app/tenants`).
  static const String CENTRAL_HOST = 'main.safeworsolutions.com';
}
