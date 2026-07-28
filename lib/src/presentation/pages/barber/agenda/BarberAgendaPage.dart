import 'package:ecommerce_flutter/src/data/dataSource/remote/services/BarberApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/barber/BarberModels.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Agenda del día (feature premium: barber_agenda) — modo administrador.
/// Requiere el token de la app (X-App-Token); muestra las citas del día
/// agrupadas por barbero, con datos de contacto del cliente.
class BarberAgendaPage extends StatefulWidget {
  const BarberAgendaPage({super.key});

  @override
  State<BarberAgendaPage> createState() => _BarberAgendaPageState();
}

class _BarberAgendaPageState extends State<BarberAgendaPage> {
  final BarberApiService _service = BarberApiService();

  DateTime _date = DateTime.now();
  List<AgendaCita>? _citas;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _dateYmd => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.agenda(date: _dateYmd);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res is Success<List<AgendaCita>>) {
        _citas = res.data;
      } else if (res is Error<List<AgendaCita>>) {
        _error = res.message;
        _citas = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _load();
  }

  void _setDate(DateTime d) {
    setState(() => _date = d);
    _load();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _hora(String raw) {
    try {
      return DateFormat('h:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw.length >= 16 ? raw.substring(11, 16) : raw;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text('Agenda del día',
            style: TextStyle(
                color: cs.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                _dateChip('Hoy', _sameDay(_date, today), () => _setDate(today),
                    cs),
                const SizedBox(width: 8),
                _dateChip('Mañana', _sameDay(_date, tomorrow),
                    () => _setDate(tomorrow), cs),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('d/M/yyyy').format(_date),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onBackground),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(cs, tokens)),
        ],
      ),
    );
  }

  Widget _dateChip(
      String label, bool selected, VoidCallback onTap, ColorScheme cs) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? cs.primary : cs.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, AppTokens tokens) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textMuted, fontSize: 13)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final citas = _citas ?? [];
    if (citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined,
                size: 64, color: tokens.textSubtle),
            const SizedBox(height: 14),
            Text('Sin citas para este día',
                style: TextStyle(color: tokens.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    // Agrupar por barbero conservando el orden por hora.
    final grupos = <String, List<AgendaCita>>{};
    for (final c in citas) {
      grupos.putIfAbsent(c.barbero, () => []).add(c);
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: grupos.entries.expand((entry) {
          return <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.content_cut, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: tokens.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: cs.outline, height: 1)),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value.length}',
                    style: TextStyle(fontSize: 12, color: tokens.textMuted),
                  ),
                ],
              ),
            ),
            ...entry.value.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCitaCard(c, cs, tokens),
                )),
          ];
        }).toList(),
      ),
    );
  }

  Widget _buildCitaCard(AgendaCita cita, ColorScheme cs, AppTokens tokens) {
    final color = _statusColor(cita.status, cs, tokens);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_hora(cita.startsAt)} – ${_hora(cita.endsAt)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onBackground),
                    ),
                    if (cita.isAuto) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.autorenew, size: 13, color: cs.primary),
                    ],
                    const Spacer(),
                    Text(
                      '₡${fmtPrice(cita.totalCents / 100)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  cita.clienteNombre,
                  style: TextStyle(fontSize: 13, color: cs.onBackground),
                ),
                const SizedBox(height: 2),
                Text(
                  cita.servicios.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: tokens.textMuted),
                ),
              ],
            ),
          ),
          if (cita.clienteTelefono?.isNotEmpty ?? false)
            IconButton(
              onPressed: () async {
                final uri = Uri.parse('tel:${cita.clienteTelefono}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              icon: Icon(Icons.phone_outlined, size: 20, color: cs.primary),
            ),
        ],
      ),
    );
  }
}
