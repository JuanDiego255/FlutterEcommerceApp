import 'dart:convert';

import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/barber/BarberModels.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Cliente del flujo público de reservas de barbería (/api/barber/*).
/// Sin tokens: es el mismo flujo abierto de la landing web. El backend
/// resuelve el tenant por dominio (InitializeTenancyByDomain).
class BarberApiService {
  String get _host => TenantSession.host;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Duration _timeout = Duration(seconds: 15);

  /// Landing: tenant (título/logo/whatsapp) + barberos activos.
  Future<Resource<BarberHomeData>> home() async {
    try {
      final url = Uri.https(_host, '/api/barber/home');
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(BarberHomeData.fromJson(body));
      }
      return Error(_parseError(res, 'No se pudo cargar la barbería'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Token anti-bot del formulario (mismo mecanismo que la web: se pide al
  /// abrir el formulario y se envía en el POST de la reserva).
  Future<String?> bookingToken() async {
    try {
      final url = Uri.https(_host, '/api/barber/booking-token');
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return body['token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Servicios del barbero (el general devuelve todos los activos).
  Future<Resource<List<BarberServiceItem>>> servicios(int barberoId) async {
    try {
      final url = Uri.https(_host, '/api/barber/barberos/$barberoId/servicios');
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return Success(list
            .map((e) => BarberServiceItem.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      return Error(_parseError(res, 'No se pudieron cargar los servicios'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Slots libres del barbero para la fecha y servicios elegidos.
  Future<Resource<List<String>>> disponibilidad({
    required int barberoId,
    required String date, // Y-m-d
    required List<int> servicioIds,
  }) async {
    try {
      final url = Uri.https(
        _host,
        '/api/barber/barberos/$barberoId/disponibilidad',
        _serviciosQuery(date, servicioIds),
      );
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(((body['slots'] as List<dynamic>?) ?? [])
            .map((e) => e.toString())
            .toList());
      }
      return Error(_parseError(res, 'No se pudo consultar la disponibilidad'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Flujo del barbero general: barberos con todos los servicios pedidos y
  /// al menos un slot libre en la fecha.
  Future<Resource<List<AvailableBarber>>> disponiblesPara({
    required String date,
    required List<int> servicioIds,
  }) async {
    try {
      final url = Uri.https(
        _host,
        '/api/barber/barberos/disponibles-para',
        _serviciosQuery(date, servicioIds),
      );
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return Success(list
            .map((e) => AvailableBarber.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      return Error(_parseError(res, 'No se pudo consultar los barberos'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Crea la reserva. El backend aplica las mismas validaciones que la web
  /// (disponibilidad atómica, auto-booking, email verificado, anti-bot) y
  /// encola los correos — la respuesta es inmediata.
  Future<Resource<BookingConfirmation>> reservar({
    required int barberoId,
    required String clienteNombre,
    required String clienteEmail,
    String? clienteTelefono,
    required List<int> servicioIds,
    required String date, // Y-m-d
    required String time, // slot tal cual llega de disponibilidad ("9:00 AM")
    required String formToken,
  }) async {
    try {
      final url = Uri.https(_host, '/api/barber/reservas');
      final res = await http
          .post(
            url,
            headers: _headers,
            body: json.encode({
              'barbero_id': barberoId,
              'cliente_nombre': clienteNombre,
              'cliente_email': clienteEmail,
              'cliente_telefono':
                  (clienteTelefono?.isNotEmpty ?? false) ? clienteTelefono : null,
              'servicios': servicioIds,
              'date': date,
              'time': time,
              '_form_token': formToken,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 201) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(BookingConfirmation.fromJson(
            (body['cita'] as Map<String, dynamic>?) ?? const {}));
      }
      return Error(_parseError(res, 'No se pudo crear la reserva'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  // ─── Funciones premium (el backend responde 403 si no están activas) ────

  /// Galería de trabajos del barbero [feature: gallery].
  Future<Resource<List<BarberPhotoItem>>> trabajos(int barberoId) async {
    try {
      final url = Uri.https(_host, '/api/barber/barberos/$barberoId/trabajos');
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return Success(list
            .map((e) => BarberPhotoItem.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      return Error(_parseError(res, 'No se pudo cargar la galería'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Citas del cliente por email [feature: my_bookings].
  Future<Resource<List<ClientBooking>>> misCitas(String email) async {
    try {
      final url =
          Uri.https(_host, '/api/barber/mis-citas', {'email': email});
      final res = await http.get(url, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(((body['citas'] as List<dynamic>?) ?? [])
            .map((e) => ClientBooking.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      return Error(_parseError(res, 'No se pudieron consultar tus citas'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Cancela una cita del cliente [feature: my_bookings].
  Future<Resource<String>> cancelarCita(int citaId, String email) async {
    try {
      final url = Uri.https(_host, '/api/barber/citas/$citaId/cancelar');
      final res = await http
          .post(url, headers: _headers, body: json.encode({'email': email}))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(body['message']?.toString() ?? 'Tu cita fue cancelada.');
      }
      return Error(_parseError(res, 'No se pudo cancelar la cita'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Opt-in de auto-reserva recurrente [feature: auto_booking].
  Future<Resource<String>> autoBookingOptIn({
    required String email,
    required int barberoId,
    required int frequencyWeeks,
    required int dayOfWeek, // 0=domingo ... 6=sábado (convención backend)
    required String time,
    String? baseDate, // Y-m-d
  }) async {
    try {
      final url = Uri.https(_host, '/api/barber/auto-booking');
      final res = await http
          .post(
            url,
            headers: _headers,
            body: json.encode({
              'email': email,
              'enabled': true,
              'barbero_id': barberoId,
              'frequency_weeks': frequencyWeeks,
              'day_of_week': dayOfWeek,
              'time': time,
              'base_date': baseDate,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(body['message']?.toString() ?? '¡Auto-reserva activada!');
      }
      return Error(_parseError(res, 'No se pudo activar la auto-reserva'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  /// Agenda del día [feature: barber_agenda] — requiere X-App-Token
  /// (modo administrador configurado en la app).
  Future<Resource<List<AgendaCita>>> agenda({String? date}) async {
    final appToken = TenantSession.appToken;
    if (appToken == null || appToken.isEmpty) {
      return Error('Configurá el token de administrador para ver la agenda.');
    }
    try {
      final url = Uri.https(_host, '/api/barber/agenda',
          date != null ? {'date': date} : null);
      final res = await http.get(url, headers: {
        ..._headers,
        'X-App-Token': appToken,
      }).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return Success(((body['citas'] as List<dynamic>?) ?? [])
            .map((e) => AgendaCita.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      if (res.statusCode == 401) {
        return Error('Token de administrador inválido. Configuralo de nuevo.');
      }
      return Error(_parseError(res, 'No se pudo cargar la agenda'));
    } catch (e) {
      return Error('Sin conexión. Verificá tu internet e intentá de nuevo.');
    }
  }

  Map<String, dynamic> _serviciosQuery(String date, List<int> servicioIds) => {
        'date': date,
        // Laravel espera arrays como servicios[]=1&servicios[]=2
        'servicios[]': servicioIds.map((e) => e.toString()).toList(),
      };

  String _parseError(http.Response res, String fallback) {
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      // Laravel: {"message": "...", "errors": {"campo": ["msg", ...]}}
      final errors = body['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      return body['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
