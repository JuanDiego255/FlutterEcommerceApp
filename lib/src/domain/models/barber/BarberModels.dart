/// Modelos del flujo de reservas de barbería (API /api/barber/*).

/// Barbero de la landing. `isGeneral` es el comodín: muestra todos los
/// servicios y el cliente elige después entre los barberos disponibles.
class Barber {
  final int id;
  final String nombre;
  final bool isGeneral;
  final String? photoUrl;

  const Barber({
    required this.id,
    required this.nombre,
    required this.isGeneral,
    this.photoUrl,
  });

  factory Barber.fromJson(Map<String, dynamic> j) => Barber(
        id: j['id'] as int,
        nombre: j['nombre'] as String? ?? '',
        isGeneral: j['is_general'] == true,
        photoUrl: j['photo_url'] as String?,
      );
}

/// Datos del tenant para el encabezado de la landing.
class BarbershopInfo {
  final String? title;
  final String? logoUrl;
  final String? whatsapp;

  const BarbershopInfo({this.title, this.logoUrl, this.whatsapp});

  factory BarbershopInfo.fromJson(Map<String, dynamic> j) => BarbershopInfo(
        title: j['title'] as String?,
        logoUrl: j['logo_url'] as String?,
        whatsapp: j['whatsapp'] as String?,
      );
}

/// Respuesta de GET /api/barber/home.
class BarberHomeData {
  final BarbershopInfo tenant;
  final List<Barber> barberos;

  /// Funciones premium habilitadas en la central (frescas del backend).
  final List<String> features;

  const BarberHomeData({
    required this.tenant,
    required this.barberos,
    this.features = const [],
  });

  factory BarberHomeData.fromJson(Map<String, dynamic> j) => BarberHomeData(
        tenant: BarbershopInfo.fromJson(
            (j['tenant'] as Map<String, dynamic>?) ?? const {}),
        barberos: ((j['barberos'] as List<dynamic>?) ?? [])
            .map((e) => Barber.fromJson(e as Map<String, dynamic>))
            .toList(),
        features: ((j['features'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Foto de la galería de trabajos del barbero (feature: gallery).
class BarberPhotoItem {
  final int id;
  final String url;
  final String? thumbUrl;
  final String? caption;

  const BarberPhotoItem({
    required this.id,
    required this.url,
    this.thumbUrl,
    this.caption,
  });

  factory BarberPhotoItem.fromJson(Map<String, dynamic> j) => BarberPhotoItem(
        id: j['id'] as int,
        url: j['url'] as String? ?? '',
        thumbUrl: j['thumb_url'] as String?,
        caption: j['caption'] as String?,
      );
}

/// Cita del cliente en "Mis citas" (feature: my_bookings).
class ClientBooking {
  final int id;
  final String barbero;
  final String startsAt;
  final String status;
  final int totalCents;
  final List<String> servicios;
  final bool canCancel;
  final String? rescheduleUrl;
  final int cancelWindowHours;

  const ClientBooking({
    required this.id,
    required this.barbero,
    required this.startsAt,
    required this.status,
    required this.totalCents,
    required this.servicios,
    required this.canCancel,
    this.rescheduleUrl,
    required this.cancelWindowHours,
  });

  factory ClientBooking.fromJson(Map<String, dynamic> j) => ClientBooking(
        id: j['id'] as int,
        barbero: j['barbero'] as String? ?? '',
        startsAt: j['starts_at'] as String? ?? '',
        status: j['status'] as String? ?? '',
        totalCents: (j['total_cents'] as num?)?.toInt() ?? 0,
        servicios: ((j['servicios'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
        canCancel: j['can_cancel'] == true,
        rescheduleUrl: j['reschedule_url'] as String?,
        cancelWindowHours: (j['cancel_window_hours'] as num?)?.toInt() ?? 0,
      );
}

/// Cita de la agenda del día (feature: barber_agenda, modo admin).
class AgendaCita {
  final int id;
  final String barbero;
  final String clienteNombre;
  final String? clienteTelefono;
  final String startsAt;
  final String endsAt;
  final String status;
  final int totalCents;
  final bool isAuto;
  final List<String> servicios;

  const AgendaCita({
    required this.id,
    required this.barbero,
    required this.clienteNombre,
    this.clienteTelefono,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.totalCents,
    required this.isAuto,
    required this.servicios,
  });

  factory AgendaCita.fromJson(Map<String, dynamic> j) => AgendaCita(
        id: j['id'] as int,
        barbero: j['barbero'] as String? ?? '',
        clienteNombre: j['cliente_nombre'] as String? ?? '',
        clienteTelefono: j['cliente_telefono'] as String?,
        startsAt: j['starts_at'] as String? ?? '',
        endsAt: j['ends_at'] as String? ?? '',
        status: j['status'] as String? ?? '',
        totalCents: (j['total_cents'] as num?)?.toInt() ?? 0,
        isAuto: j['is_auto'] == true,
        servicios: ((j['servicios'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Servicio ofrecido (precio pivot por barbero o precio base).
class BarberServiceItem {
  final int id;
  final String nombre;
  final String? descripcion;
  final int priceCents;
  final int durationMinutes;

  const BarberServiceItem({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.priceCents,
    required this.durationMinutes,
  });

  factory BarberServiceItem.fromJson(Map<String, dynamic> j) =>
      BarberServiceItem(
        id: j['id'] as int,
        nombre: j['nombre'] as String? ?? '',
        descripcion: j['descripcion'] as String?,
        priceCents: (j['price_cents'] as num?)?.toInt() ?? 0,
        durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 0,
      );
}

/// Barbero disponible para el flujo del barbero general: incluye los slots
/// libres del día pedido.
class AvailableBarber {
  final Barber barber;
  final List<String> slots;

  const AvailableBarber({required this.barber, required this.slots});

  factory AvailableBarber.fromJson(Map<String, dynamic> j) => AvailableBarber(
        barber: Barber.fromJson(j),
        slots: ((j['slots'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Cita confirmada devuelta por POST /api/barber/reservas.
class BookingConfirmation {
  final int id;
  final String barbero;
  final String startsAt;
  final int totalCents;
  final List<BookingConfirmationService> servicios;

  const BookingConfirmation({
    required this.id,
    required this.barbero,
    required this.startsAt,
    required this.totalCents,
    required this.servicios,
  });

  factory BookingConfirmation.fromJson(Map<String, dynamic> j) =>
      BookingConfirmation(
        id: j['id'] as int,
        barbero: j['barbero'] as String? ?? '',
        startsAt: j['starts_at'] as String? ?? '',
        totalCents: (j['total_cents'] as num?)?.toInt() ?? 0,
        servicios: ((j['servicios'] as List<dynamic>?) ?? [])
            .map((e) =>
                BookingConfirmationService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BookingConfirmationService {
  final String nombre;
  final int priceCents;
  final int durationMinutes;

  const BookingConfirmationService({
    required this.nombre,
    required this.priceCents,
    required this.durationMinutes,
  });

  factory BookingConfirmationService.fromJson(Map<String, dynamic> j) =>
      BookingConfirmationService(
        nombre: j['nombre'] as String? ?? '',
        priceCents: (j['price_cents'] as num?)?.toInt() ?? 0,
        durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 0,
      );
}
