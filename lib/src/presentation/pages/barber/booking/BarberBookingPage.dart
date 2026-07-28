import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/BarberApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/barber/BarberModels.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wizard de reserva — flujo idéntico a la versión web:
///
/// Barbero específico (4 pasos):
///   1. Servicios  →  2. Fecha  →  3. Horario  →  4. Tus datos
/// Barbero general (5 pasos):
///   1. Servicios  →  2. Fecha  →  3. Barbero disponible  →  4. Horario  →  5. Tus datos
///
/// Cada paso habilita el siguiente (los bloqueados se ven atenuados y no
/// responden, como .step-locked en la web). Cambiar un paso anterior
/// resetea los siguientes y re-consulta disponibilidad.
class BarberBookingPage extends StatefulWidget {
  const BarberBookingPage({super.key});

  @override
  State<BarberBookingPage> createState() => _BarberBookingPageState();
}

class _BarberBookingPageState extends State<BarberBookingPage> {
  final BarberApiService _service = BarberApiService();

  Barber? _barber;

  // Paso 1 — servicios
  List<BarberServiceItem>? _services;
  String? _servicesError;
  final Set<int> _selectedServiceIds = {};

  // Paso 2 — fecha
  DateTime? _date;

  // Paso 3 (solo barbero general) — barbero disponible
  List<AvailableBarber>? _availableBarbers;
  bool _loadingBarbers = false;
  String? _barbersError;
  AvailableBarber? _chosenBarber;

  // Paso horario
  List<String>? _slots;
  bool _loadingSlots = false;
  String? _slotsError;
  String? _selectedSlot;
  int _requestSeq = 0; // descarta respuestas de consultas viejas

  // Paso datos del cliente
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _formToken; // anti-bot, se pide al abrir el formulario
  bool _submitting = false;

  bool get _isGeneral => _barber?.isGeneral ?? false;
  int get _totalSteps => _isGeneral ? 5 : 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_barber == null) {
      _barber = ModalRoute.of(context)?.settings.arguments as Barber?;
      _loadServices();
      _loadFormToken();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ─── Carga de datos ──────────────────────────────────────────────────────

  Future<void> _loadFormToken() async {
    _formToken = await _service.bookingToken();
  }

  Future<void> _loadServices() async {
    final barber = _barber;
    if (barber == null) return;
    setState(() {
      _services = null;
      _servicesError = null;
    });
    final res = await _service.servicios(barber.id);
    if (!mounted) return;
    setState(() {
      if (res is Success<List<BarberServiceItem>>) {
        _services = res.data;
      } else if (res is Error<List<BarberServiceItem>>) {
        _servicesError = res.message;
      }
    });
  }

  /// Cambió un paso anterior: se invalida todo lo que depende de él.
  void _resetDownstream({bool keepDate = true}) {
    if (!keepDate) _date = null;
    _availableBarbers = null;
    _barbersError = null;
    _chosenBarber = null;
    _slots = null;
    _slotsError = null;
    _selectedSlot = null;
  }

  void _toggleService(int id) {
    setState(() {
      if (_selectedServiceIds.contains(id)) {
        _selectedServiceIds.remove(id);
      } else {
        _selectedServiceIds.add(id);
      }
      _resetDownstream();
    });
    if (_selectedServiceIds.isNotEmpty && _date != null) {
      _fetchAvailability();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _resetDownstream();
    });
    _fetchAvailability();
  }

  String get _dateYmd => DateFormat('yyyy-MM-dd').format(_date!);

  Future<void> _fetchAvailability() async {
    if (_selectedServiceIds.isEmpty || _date == null) return;
    final seq = ++_requestSeq;

    if (_isGeneral) {
      setState(() {
        _loadingBarbers = true;
        _barbersError = null;
      });
      final res = await _service.disponiblesPara(
        date: _dateYmd,
        servicioIds: _selectedServiceIds.toList(),
      );
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loadingBarbers = false;
        if (res is Success<List<AvailableBarber>>) {
          _availableBarbers = res.data;
          // Si ya había un barbero elegido, sincronizar con el listado
          // fresco (sus slots pudieron cambiar o pudo quedar sin cupo).
          if (_chosenBarber != null) {
            final match = res.data
                .where((ab) => ab.barber.id == _chosenBarber!.barber.id)
                .toList();
            if (match.isEmpty) {
              _chosenBarber = null;
              _slots = null;
              _selectedSlot = null;
            } else {
              _chosenBarber = match.first;
              _slots = match.first.slots;
              if (_selectedSlot != null && !_slots!.contains(_selectedSlot)) {
                _selectedSlot = null;
              }
            }
          }
        } else if (res is Error<List<AvailableBarber>>) {
          _barbersError = res.message;
        }
      });
    } else {
      setState(() {
        _loadingSlots = true;
        _slotsError = null;
      });
      final res = await _service.disponibilidad(
        barberoId: _barber!.id,
        date: _dateYmd,
        servicioIds: _selectedServiceIds.toList(),
      );
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loadingSlots = false;
        if (res is Success<List<String>>) {
          _slots = res.data;
          if (_selectedSlot != null && !_slots!.contains(_selectedSlot)) {
            _selectedSlot = null;
          }
        } else if (res is Error<List<String>>) {
          _slotsError = res.message;
        }
      });
    }
  }

  void _chooseBarber(AvailableBarber b) {
    setState(() {
      _chosenBarber = b;
      _slots = b.slots;
      _slotsError = null;
      _selectedSlot = null;
    });
  }

  // ─── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting || _selectedSlot == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    var token = _formToken;
    token ??= await _service.bookingToken();
    if (token == null) {
      if (mounted) {
        setState(() => _submitting = false);
        Fluttertoast.showToast(
            msg: 'No se pudo preparar el formulario. Intentá de nuevo.',
            toastLength: Toast.LENGTH_LONG);
      }
      return;
    }

    final barberoId = _isGeneral ? _chosenBarber!.barber.id : _barber!.id;
    final res = await _service.reservar(
      barberoId: barberoId,
      clienteNombre: _nameCtrl.text.trim(),
      clienteEmail: _emailCtrl.text.trim(),
      clienteTelefono: _phoneCtrl.text.trim(),
      servicioIds: _selectedServiceIds.toList(),
      date: _dateYmd,
      time: _selectedSlot!,
      formToken: token,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res is Success<BookingConfirmation>) {
      // Recordar el email para "Mis citas" y próximas reservas.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('barber_client_email', _emailCtrl.text.trim());
      if (!mounted) return;
      await _showSuccess(res.data);
      if (mounted) Navigator.pop(context); // vuelve a la landing
    } else if (res is Error<BookingConfirmation>) {
      Fluttertoast.showToast(msg: res.message, toastLength: Toast.LENGTH_LONG);
      // El slot pudo ocuparse mientras completaban el formulario:
      // se refresca la disponibilidad para reflejar el estado real.
      _fetchAvailability();
    }
  }

  // ─── Totales ─────────────────────────────────────────────────────────────

  List<BarberServiceItem> get _selectedServices =>
      (_services ?? []).where((s) => _selectedServiceIds.contains(s.id)).toList();

  int get _totalCents =>
      _selectedServices.fold(0, (sum, s) => sum + s.priceCents);

  int get _totalMinutes =>
      _selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

  String _fmtDate(DateTime d) {
    try {
      return DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(d);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(d);
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final barber = _barber;

    if (barber == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Barbero no válido',
              style: TextStyle(color: tokens.textMuted)),
        ),
      );
    }

    // Estado de cada paso
    final servicesDone = _selectedServiceIds.isNotEmpty;
    final dateDone = _date != null;
    final barberDone = !_isGeneral || _chosenBarber != null;
    final slotDone = _selectedSlot != null;

    final completed = [
      servicesDone,
      dateDone,
      if (_isGeneral) _chosenBarber != null,
      slotDone,
    ].where((e) => e).length;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text(
          barber.nombre,
          style: TextStyle(
              color: cs.onBackground, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          // Barra de progreso del wizard
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RESERVÁ TU CITA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: tokens.textMuted,
                      ),
                    ),
                    Text(
                      '$completed de $_totalSteps pasos',
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: completed / _totalSteps,
                    minHeight: 5,
                    backgroundColor: tokens.surfaceAlt,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _StepCard(
                  number: 1,
                  title: 'Servicios',
                  subtitle: 'Elegí uno o varios',
                  done: servicesDone,
                  locked: false,
                  child: _buildServicesStep(cs, tokens),
                ),
                const SizedBox(height: 12),
                _StepCard(
                  number: 2,
                  title: 'Fecha',
                  subtitle: 'Cuándo querés venir',
                  done: dateDone,
                  locked: !servicesDone,
                  child: _buildDateStep(cs, tokens),
                ),
                if (_isGeneral) ...[
                  const SizedBox(height: 12),
                  _StepCard(
                    number: 3,
                    title: 'Barbero',
                    subtitle: 'Disponibles para tu fecha',
                    done: _chosenBarber != null,
                    locked: !servicesDone || !dateDone,
                    child: _buildBarbersStep(cs, tokens),
                  ),
                ],
                const SizedBox(height: 12),
                _StepCard(
                  number: _isGeneral ? 4 : 3,
                  title: 'Horario',
                  subtitle: 'Horas disponibles',
                  done: slotDone,
                  locked: !servicesDone || !dateDone || !barberDone,
                  child: _buildSlotsStep(cs, tokens),
                ),
                const SizedBox(height: 12),
                _StepCard(
                  number: _isGeneral ? 5 : 4,
                  title: 'Tus datos',
                  subtitle: 'Para confirmarte la cita',
                  done: false,
                  locked: !slotDone,
                  child: _buildClientStep(cs, tokens),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Paso 1: servicios ───────────────────────────────────────────────────

  Widget _buildServicesStep(ColorScheme cs, AppTokens tokens) {
    if (_servicesError != null) {
      return _inlineError(_servicesError!, _loadServices, tokens);
    }
    if (_services == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
            child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        )),
      );
    }
    if (_services!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Este barbero no tiene servicios activos',
            style: TextStyle(fontSize: 13, color: tokens.textMuted)),
      );
    }

    return Column(
      children: _services!.map((s) {
        final selected = _selectedServiceIds.contains(s.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _toggleService(s.id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? cs.primary.withOpacity(0.08) : cs.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? cs.primary : cs.outline,
                    width: selected ? 1.2 : 1),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? cs.primary : tokens.textSubtle,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onBackground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.durationMinutes} min',
                          style:
                              TextStyle(fontSize: 11, color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₡${fmtPrice(s.priceCents / 100)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.primary : cs.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Paso 2: fecha ───────────────────────────────────────────────────────

  Widget _buildDateStep(ColorScheme cs, AppTokens tokens) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _date != null ? cs.primary : cs.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 20, color: _date != null ? cs.primary : tokens.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _date != null ? _fmtDate(_date!) : 'Seleccioná una fecha',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _date != null ? FontWeight.w600 : FontWeight.w400,
                  color: _date != null ? cs.onBackground : tokens.textMuted,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }

  // ─── Paso 3 (general): barbero disponible ────────────────────────────────

  Widget _buildBarbersStep(ColorScheme cs, AppTokens tokens) {
    if (_loadingBarbers) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
            child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        )),
      );
    }
    if (_barbersError != null) {
      return _inlineError(_barbersError!, _fetchAvailability, tokens);
    }
    if (_availableBarbers == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Elegí servicios y fecha para ver los barberos',
            style: TextStyle(fontSize: 13, color: tokens.textMuted)),
      );
    }
    if (_availableBarbers!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
            'No hay barberos disponibles ese día para los servicios elegidos. Probá con otra fecha.',
            style: TextStyle(fontSize: 13, color: tokens.textMuted)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableBarbers!.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final ab = _availableBarbers![index];
          final selected = _chosenBarber?.barber.id == ab.barber.id;
          return InkWell(
            onTap: () => _chooseBarber(ab),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? cs.primary.withOpacity(0.08) : cs.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? cs.primary : cs.outline,
                    width: selected ? 1.2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.surfaceAlt,
                      border: Border.all(
                          color: selected ? cs.primary : cs.outline),
                    ),
                    child: (ab.barber.photoUrl?.isNotEmpty ?? false)
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: ab.barber.photoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                  Icons.person_outline,
                                  size: 22,
                                  color: tokens.textSubtle),
                            ),
                          )
                        : Icon(Icons.person_outline,
                            size: 22, color: tokens.textSubtle),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ab.barber.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ab.slots.length} horarios',
                    style: TextStyle(fontSize: 10, color: tokens.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Paso horario ────────────────────────────────────────────────────────

  Widget _buildSlotsStep(ColorScheme cs, AppTokens tokens) {
    if (_loadingSlots) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
            child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        )),
      );
    }
    if (_slotsError != null) {
      return _inlineError(_slotsError!, _fetchAvailability, tokens);
    }
    if (_slots == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          _isGeneral
              ? 'Elegí un barbero para ver sus horarios'
              : 'Elegí servicios y fecha para ver los horarios',
          style: TextStyle(fontSize: 13, color: tokens.textMuted),
        ),
      );
    }
    if (_slots!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
            'No hay horas disponibles para esa fecha. Probá con otro día.',
            style: TextStyle(fontSize: 13, color: tokens.textMuted)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _slots!.map((slot) {
        final selected = _selectedSlot == slot;
        return InkWell(
          onTap: () => setState(() => _selectedSlot = slot),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? cs.primary : cs.background,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: selected ? cs.primary : cs.outline),
            ),
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? cs.onPrimary : cs.onBackground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Paso datos del cliente + resumen + submit ───────────────────────────

  Widget _buildClientStep(ColorScheme cs, AppTokens tokens) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Nombre completo *',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Correo electrónico *',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Ingresá tu correo';
              final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRe.hasMatch(value)) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Teléfono (opcional)',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummary(cs, tokens),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  : const Text('Reservar cita'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme cs, AppTokens tokens) {
    final barberName =
        _isGeneral ? (_chosenBarber?.barber.nombre ?? '—') : _barber!.nombre;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          _summaryRow('Barbero', barberName, cs, tokens),
          const SizedBox(height: 6),
          _summaryRow(
              'Fecha', _date != null ? _fmtDate(_date!) : '—', cs, tokens),
          const SizedBox(height: 6),
          _summaryRow('Hora', _selectedSlot ?? '—', cs, tokens),
          const SizedBox(height: 6),
          _summaryRow('Duración', '$_totalMinutes min', cs, tokens),
          const SizedBox(height: 10),
          Divider(color: cs.outline, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isGeneral ? 'Total estimado' : 'Total',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onBackground),
              ),
              Text(
                '₡${fmtPrice(_totalCents / 100)}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      String label, String value, ColorScheme cs, AppTokens tokens) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: tokens.textMuted)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onBackground),
          ),
        ),
      ],
    );
  }

  Widget _inlineError(String message, VoidCallback onRetry, AppTokens tokens) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tokens.textMuted)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 16, color: cs.primary),
            label: Text('Reintentar',
                style: TextStyle(fontSize: 13, color: cs.primary)),
          ),
        ],
      ),
    );
  }

  // ─── Confirmación ────────────────────────────────────────────────────────

  /// Hora del slot seleccionado como TimeOfDay ("9:00 AM" / "14:30").
  TimeOfDay? _parseSlotTime(String s) {
    final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$')
        .firstMatch(s.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ap = m.group(3)?.toUpperCase();
    if (ap == 'PM' && h != 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    if (h > 23 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  }

  DateTime? get _bookedStart {
    if (_date == null || _selectedSlot == null) return null;
    final t = _parseSlotTime(_selectedSlot!);
    if (t == null) return null;
    return DateTime(_date!.year, _date!.month, _date!.day, t.hour, t.minute);
  }

  void _addToCalendar(BookingConfirmation cita) {
    final start = _bookedStart;
    if (start == null) return;
    final event = Event(
      title: 'Cita: ${cita.barbero}',
      description: cita.servicios.map((s) => s.nombre).join(', '),
      startDate: start,
      endDate: start.add(Duration(minutes: _totalMinutes > 0 ? _totalMinutes : 30)),
    );
    Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _showSuccess(BookingConfirmation cita) async {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.check_rounded, size: 36, color: tokens.success),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Cita reservada!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onBackground),
            ),
            const SizedBox(height: 6),
            Text(
              'Te enviamos la confirmación por correo con los detalles y opciones para reprogramar o cancelar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tokens.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  _summaryRow('Cita', '#${cita.id}', cs, tokens),
                  const SizedBox(height: 6),
                  _summaryRow('Barbero', cita.barbero, cs, tokens),
                  const SizedBox(height: 6),
                  _summaryRow('Fecha y hora', cita.startsAt, cs, tokens),
                  const SizedBox(height: 6),
                  _summaryRow(
                    'Servicios',
                    cita.servicios.map((s) => s.nombre).join(', '),
                    cs,
                    tokens,
                  ),
                  const SizedBox(height: 10),
                  Divider(color: cs.outline, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onBackground)),
                      Text(
                        '₡${fmtPrice(cita.totalCents / 100)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (TenantSession.hasFeature('calendar') && _bookedStart != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _addToCalendar(cita),
                  icon: Icon(Icons.calendar_month_outlined,
                      size: 18, color: cs.primary),
                  label: Text(
                    'Agregar al calendario',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            if (TenantSession.hasFeature('auto_booking')) ...[
              const SizedBox(height: 12),
              _AutoBookingCard(
                service: _service,
                email: _emailCtrl.text.trim(),
                barberoId:
                    _isGeneral ? _chosenBarber!.barber.id : _barber!.id,
                dayOfWeek: _date!.weekday % 7, // Dart lun=1..dom=7 → 0=domingo
                time: _selectedSlot!,
                baseDate: _dateYmd,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Listo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Auto-reserva recurrente (feature premium: auto_booking) ─────────────────

/// Tarjeta del sheet de confirmación: "¿Repetimos esta cita?" — el cliente
/// elige la frecuencia y el backend deja configurado el opt-in que el
/// auto-scheduler ya consume (misma cadencia, día y hora de la cita).
class _AutoBookingCard extends StatefulWidget {
  final BarberApiService service;
  final String email;
  final int barberoId;
  final int dayOfWeek;
  final String time;
  final String baseDate;

  const _AutoBookingCard({
    required this.service,
    required this.email,
    required this.barberoId,
    required this.dayOfWeek,
    required this.time,
    required this.baseDate,
  });

  @override
  State<_AutoBookingCard> createState() => _AutoBookingCardState();
}

class _AutoBookingCardState extends State<_AutoBookingCard> {
  int _weeks = 2;
  bool _busy = false;
  bool _done = false;

  Future<void> _activate() async {
    if (_busy || _done) return;
    setState(() => _busy = true);
    final res = await widget.service.autoBookingOptIn(
      email: widget.email,
      barberoId: widget.barberoId,
      frequencyWeeks: _weeks,
      dayOfWeek: widget.dayOfWeek,
      time: widget.time,
      baseDate: widget.baseDate,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = res is Success<String>;
    });
    if (res is Success<String>) {
      Fluttertoast.showToast(msg: res.data, toastLength: Toast.LENGTH_LONG);
    } else if (res is Error<String>) {
      Fluttertoast.showToast(msg: res.message, toastLength: Toast.LENGTH_LONG);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    if (_done) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.success.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.autorenew, size: 18, color: tokens.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Auto-reserva activada: te propondremos la próxima cita por correo.',
                style: TextStyle(fontSize: 12, color: cs.onBackground),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.autorenew, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¿Repetimos esta cita automáticamente?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onBackground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mismo barbero, mismo día y hora. Te llega la propuesta por correo y decidís.',
            style: TextStyle(fontSize: 11, color: tokens.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [1, 2, 4].map((w) {
                    final selected = _weeks == w;
                    return InkWell(
                      onTap: () => setState(() => _weeks = w),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? cs.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: selected ? cs.primary : cs.outline),
                        ),
                        child: Text(
                          w == 1 ? 'Cada semana' : 'Cada $w sem.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                selected ? cs.onPrimary : cs.onBackground,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              _busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    )
                  : TextButton(
                      onPressed: _activate,
                      child: Text(
                        'Activar',
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step card ───────────────────────────────────────────────────────────────

/// Contenedor de un paso del wizard: número dorado, título, check al
/// completarse; atenuado y sin interacción mientras está bloqueado
/// (equivalente a .step-locked de la web).
class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final bool done;
  final bool locked;
  final Widget child;

  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.locked,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: locked ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: locked,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: done ? tokens.success.withOpacity(0.5) : cs.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done
                          ? tokens.success.withOpacity(0.15)
                          : cs.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? Icon(Icons.check_rounded,
                            size: 15, color: tokens.success)
                        : Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onBackground,
                          ),
                        ),
                        Text(
                          subtitle,
                          style:
                              TextStyle(fontSize: 11, color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
