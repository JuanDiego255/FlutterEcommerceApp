import 'package:ecommerce_flutter/src/data/dataSource/remote/services/BarberApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/barber/BarberModels.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Mis citas" (feature premium: my_bookings) — el cliente consulta sus
/// citas por email, cancela dentro de la ventana permitida (mismas reglas
/// que la web) y reprograma vía el enlace firmado del backend.
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final BarberApiService _service = BarberApiService();
  final _emailCtrl = TextEditingController();

  List<ClientBooking>? _citas;
  bool _loading = false;
  String? _error;
  final Set<int> _cancelling = {};

  @override
  void initState() {
    super.initState();
    _prefillEmail();
  }

  Future<void> _prefillEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('barber_client_email');
    if (saved != null && saved.isNotEmpty && mounted) {
      _emailCtrl.text = saved;
      _search();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.misCitas(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res is Success<List<ClientBooking>>) {
        _citas = res.data;
        SharedPreferences.getInstance()
            .then((p) => p.setString('barber_client_email', email));
      } else if (res is Error<List<ClientBooking>>) {
        _error = res.message;
      }
    });
  }

  Future<void> _cancel(ClientBooking cita) async {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar cita',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.onBackground)),
        content: Text(
          '¿Seguro que querés cancelar tu cita del ${_fmtDateTime(cita.startsAt)} con ${cita.barbero}?',
          style: TextStyle(color: tokens.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Volver', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling.add(cita.id));
    final res = await _service.cancelarCita(cita.id, _emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _cancelling.remove(cita.id));

    if (res is Success<String>) {
      Fluttertoast.showToast(msg: res.data, toastLength: Toast.LENGTH_LONG);
      _search();
    } else if (res is Error<String>) {
      Fluttertoast.showToast(msg: res.message, toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<void> _reschedule(ClientBooking cita) async {
    final url = cita.rescheduleUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _fmtDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("d MMM yyyy, h:mm a", 'es').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status, ColorScheme cs, AppTokens tokens) {
    switch (status) {
      case 'confirmed':
        return tokens.success;
      case 'pending':
        return tokens.warning;
      case 'completed':
        return cs.primary;
      case 'cancelled':
      case 'not_arrive':
        return cs.error;
      default:
        return tokens.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendiente';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'not_arrive':
        return 'No asistió';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text('Mis citas',
            style: TextStyle(
                color: cs.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Tu correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _search,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(56, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 14)),
                    child: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.onPrimary),
                          )
                        : const Icon(Icons.search, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(cs, tokens)),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme cs, AppTokens tokens) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textMuted, fontSize: 13)),
        ),
      );
    }
    if (_citas == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, size: 64, color: tokens.textSubtle),
            const SizedBox(height: 14),
            Text('Ingresá tu correo para ver tus citas',
                style: TextStyle(color: tokens.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    if (_citas!.isEmpty) {
      return Center(
        child: Text('No encontramos citas para ese correo',
            style: TextStyle(color: tokens.textMuted, fontSize: 14)),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _search,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: _citas!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildCard(_citas![index], cs, tokens),
      ),
    );
  }

  Widget _buildCard(ClientBooking cita, ColorScheme cs, AppTokens tokens) {
    final color = _statusColor(cita.status, cs, tokens);
    final busy = _cancelling.contains(cita.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _fmtDateTime(cita.startsAt),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onBackground),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Text(
                  _statusLabel(cita.status),
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.content_cut, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${cita.barbero}  •  ${cita.servicios.join(', ')}',
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),
              ),
              Text(
                '₡${fmtPrice(cita.totalCents / 100)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.primary),
              ),
            ],
          ),
          if (cita.canCancel || cita.rescheduleUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (cita.rescheduleUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reschedule(cita),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42)),
                      icon: Icon(Icons.edit_calendar_outlined,
                          size: 16, color: cs.primary),
                      label: Text('Reprogramar',
                          style: TextStyle(fontSize: 12, color: cs.primary)),
                    ),
                  ),
                if (cita.rescheduleUrl != null && cita.canCancel)
                  const SizedBox(width: 8),
                if (cita.canCancel)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => _cancel(cita),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        side: BorderSide(color: cs.error.withOpacity(0.6)),
                      ),
                      icon: busy
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: cs.error),
                            )
                          : Icon(Icons.close, size: 16, color: cs.error),
                      label: Text('Cancelar',
                          style: TextStyle(fontSize: 12, color: cs.error)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
