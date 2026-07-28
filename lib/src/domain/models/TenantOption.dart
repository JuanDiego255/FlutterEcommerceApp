/// Una tienda del directorio central (`GET /api/app/tenants`).
///
/// Reemplaza la lista quemada del selector: los tenants habilitados para la
/// app se administran desde el panel central (tenants.app_enabled).
class TenantOption {
  static const String typeEcommerce = 'ecommerce';
  static const String typeBarbershop = 'barbershop';

  final String id;
  final String name;
  final String domain;

  /// Vertical que la app debe renderizar: [typeEcommerce] o [typeBarbershop].
  final String type;

  final String? subtitle;
  final String? location;

  /// Color de marca en hex (`#RRGGBB`), opcional.
  final String? colorHex;
  final String? logoUrl;

  /// Funciones premium habilitadas en la central (claves del catálogo del
  /// backend: my_bookings, gallery, calendar, auto_booking, branding,
  /// barber_agenda, qr_deeplink). Si no está aquí, la app no la muestra.
  final List<String> features;

  const TenantOption({
    required this.id,
    required this.name,
    required this.domain,
    required this.type,
    this.subtitle,
    this.location,
    this.colorHex,
    this.logoUrl,
    this.features = const [],
  });

  bool get isBarbershop => type == typeBarbershop;

  factory TenantOption.fromJson(Map<String, dynamic> j) => TenantOption(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        domain: j['domain'] as String? ?? '',
        type: j['type'] as String? ?? typeEcommerce,
        subtitle: j['subtitle'] as String?,
        location: j['location'] as String?,
        colorHex: j['color'] as String?,
        logoUrl: j['logo_url'] as String?,
        features: ((j['features'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'domain': domain,
        'type': type,
        'subtitle': subtitle,
        'location': location,
        'color': colorHex,
        'logo_url': logoUrl,
        'features': features,
      };
}
