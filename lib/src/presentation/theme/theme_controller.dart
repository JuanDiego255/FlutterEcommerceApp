import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:flutter/material.dart';

/// Acento de marca activo (función premium 'branding').
///
/// MaterialApp escucha [accent] y reconstruye el tema cuando cambia — al
/// seleccionar un tenant, al refrescar las features desde el backend o al
/// entrar por deep link. Null → acento dorado por defecto (Oscuro Premium).
class ThemeController {
  ThemeController._();

  static final ValueNotifier<Color?> accent = ValueNotifier<Color?>(null);

  /// Relee TenantSession y actualiza el acento. Llamar después de
  /// TenantSession.save / updateFeatures / clear.
  static void syncFromSession() {
    accent.value = _parse(TenantSession.brandColorHex);
  }

  static Color? _parse(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return value != null ? Color(value) : null;
  }
}
