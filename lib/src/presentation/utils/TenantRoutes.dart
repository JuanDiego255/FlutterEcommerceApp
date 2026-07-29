import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';

/// Traduce las rutas que vienen del backend a la vertical del tenant activo.
///
/// El API de roles/login devuelve siempre rutas de e-commerce
/// ('admin/home', 'catalog/home', 'client/home') porque el módulo de roles
/// es compartido. En un tenant de barbería esas pantallas no aplican: el
/// equivalente administrativo es la agenda del día y el equivalente de
/// cliente es la landing de barberos.
///
/// En tenants de e-commerce devuelve la ruta sin tocar — el flujo actual
/// no cambia.
class TenantRoutes {
  TenantRoutes._();

  static String resolve(String route) {
    if (!TenantSession.isBarbershop) return route;
    return route.contains('admin') ? 'barber/agenda' : TenantSession.homeRoute;
  }
}
