import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

class ApiConfig {
  static String get BASE_URL => TenantSession.host;
  static String get API_ECOMMERCE => TenantSession.host;
}
