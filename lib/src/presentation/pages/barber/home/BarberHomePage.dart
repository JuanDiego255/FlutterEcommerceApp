import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/BarberApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/barber/BarberModels.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:ecommerce_flutter/src/presentation/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Landing móvil de la barbería: encabezado con la identidad del tenant y
/// el equipo de barberos. Tocar un barbero abre el wizard de reserva
/// ('barber/booking'). Es el home de los tenants con vertical 'barbershop'
/// — no muestra nada del e-commerce.
class BarberHomePage extends StatefulWidget {
  const BarberHomePage({super.key});

  @override
  State<BarberHomePage> createState() => _BarberHomePageState();
}

class _BarberHomePageState extends State<BarberHomePage> {
  final BarberApiService _service = BarberApiService();

  BarberHomeData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _data = null;
      _error = null;
    });
    final res = await _service.home();
    if (res is Success<BarberHomeData>) {
      // La central es la fuente de verdad de las funciones premium — se
      // refrescan en cada carga del home (y el tema, si hay branding).
      await TenantSession.updateFeatures(res.data.features);
      ThemeController.syncFromSession();
    }
    if (!mounted) return;
    setState(() {
      if (res is Success<BarberHomeData>) {
        _data = res.data;
      } else if (res is Error<BarberHomeData>) {
        _error = res.message;
      }
    });
  }

  Future<void> _openWhatsApp(String whatsapp) async {
    final digits = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Scaffold(
      backgroundColor: cs.background,
      floatingActionButton: (_data?.tenant.whatsapp?.isNotEmpty ?? false)
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF25D366),
              onPressed: () => _openWhatsApp(_data!.tenant.whatsapp!),
              child: const Icon(Icons.chat, color: Colors.white),
            )
          : null,
      body: _buildBody(cs, tokens),
    );
  }

  Widget _buildBody(ColorScheme cs, AppTokens tokens) {
    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: tokens.textSubtle),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textMuted, fontSize: 14)),
              const SizedBox(height: 20),
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

    if (_data == null) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    final data = _data!;
    final general = data.barberos.where((b) => b.isGeneral).toList();
    final team = data.barberos.where((b) => !b.isGeneral).toList();

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(data.tenant, cs)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'ELEGÍ A TU BARBERO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: tokens.textMuted,
                ),
              ),
            ),
          ),
          if (general.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              sliver: SliverToBoxAdapter(
                child: _GeneralBarberCard(
                  barber: general.first,
                  onTap: () => _openBooking(general.first),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _BarberCard(
                  barber: team[index],
                  onTap: () => _onBarberTap(team[index]),
                ),
                childCount: team.length,
              ),
            ),
          ),
          if (team.isEmpty && general.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Aún no hay barberos disponibles',
                  style: TextStyle(color: tokens.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openBooking(Barber barber) {
    Navigator.pushNamed(context, 'barber/booking', arguments: barber);
  }

  /// Con la galería premium activa, tocar un barbero muestra primero su
  /// perfil con los trabajos realizados; sin ella, va directo al wizard.
  void _onBarberTap(Barber barber) {
    if (!barber.isGeneral && TenantSession.hasFeature('gallery')) {
      _showBarberSheet(barber);
    } else {
      _openBooking(barber);
    }
  }

  void _showBarberSheet(Barber barber) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.surfaceAlt,
                      border: Border.all(color: cs.outline),
                    ),
                    child: (barber.photoUrl?.isNotEmpty ?? false)
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: barber.photoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                  Icons.person_outline,
                                  color: tokens.textSubtle),
                            ),
                          )
                        : Icon(Icons.person_outline, color: tokens.textSubtle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber.nombre,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: cs.onBackground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Trabajos realizados',
                          style: TextStyle(
                              fontSize: 12, color: tokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: FutureBuilder<Resource<List<BarberPhotoItem>>>(
                  future: _service.trabajos(barber.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary),
                        ),
                      );
                    }
                    final res = snapshot.data!;
                    final fotos = res is Success<List<BarberPhotoItem>>
                        ? res.data
                        : const <BarberPhotoItem>[];
                    if (fotos.isEmpty) {
                      return Center(
                        child: Text(
                          'Este barbero aún no tiene trabajos publicados',
                          style: TextStyle(
                              fontSize: 13, color: tokens.textMuted),
                        ),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: fotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: fotos[i].thumbUrl?.isNotEmpty ?? false
                              ? fotos[i].thumbUrl!
                              : fotos[i].url,
                          width: 130,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: tokens.surfaceAlt, width: 130),
                          errorWidget: (_, __, ___) => Container(
                            color: tokens.surfaceAlt,
                            width: 130,
                            child: Icon(Icons.image_outlined,
                                color: tokens.textSubtle),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openBooking(barber);
                  },
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Agendar cita'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BarbershopInfo tenant, ColorScheme cs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bg, const Color(0xFF1C1400), cs.primary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    color: cs.surface,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (v) {
                      switch (v) {
                        case 'my_bookings':
                          Navigator.pushNamed(context, 'barber/my-bookings');
                          break;
                        case 'agenda':
                          // La agenda solo necesita el token de la app
                          // (X-App-Token); si falta, se pide y se vuelve
                          // directo acá — sin pasar por login ni roles,
                          // que son del flujo e-commerce.
                          if (TenantSession.hasAdminAccess) {
                            Navigator.pushNamed(context, 'barber/agenda');
                          } else {
                            Navigator.pushNamed(context, 'admin/token',
                                arguments: {'nextRoute': 'barber/agenda'});
                          }
                          break;
                        case 'change':
                          Navigator.pushReplacementNamed(
                              context, 'tenant/select');
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (TenantSession.hasFeature('my_bookings'))
                        PopupMenuItem(
                          value: 'my_bookings',
                          child: Row(
                            children: [
                              Icon(Icons.event_note_outlined,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 10),
                              Text('Mis citas',
                                  style: TextStyle(
                                      fontSize: 14, color: cs.onBackground)),
                            ],
                          ),
                        ),
                      if (TenantSession.hasFeature('barber_agenda'))
                        PopupMenuItem(
                          value: 'agenda',
                          child: Row(
                            children: [
                              Icon(Icons.today_outlined,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 10),
                              Text('Agenda del día',
                                  style: TextStyle(
                                      fontSize: 14, color: cs.onBackground)),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'change',
                        child: Row(
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 18, color: cs.primary),
                            const SizedBox(width: 10),
                            Text('Cambiar tienda',
                                style: TextStyle(
                                    fontSize: 14, color: cs.onBackground)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: (tenant.logoUrl?.isNotEmpty ?? false)
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: tenant.logoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.content_cut,
                              size: 30,
                              color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.content_cut,
                        size: 30, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                tenant.title ?? 'Barbería',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Reservá tu cita en segundos',
                style:
                    TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cards ─────────────────────────────────────────────────────────────────

/// Barbero comodín: tarjeta ancha destacada ("cualquier barbero").
class _GeneralBarberCard extends StatelessWidget {
  final Barber barber;
  final VoidCallback onTap;
  const _GeneralBarberCard({required this.barber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups_outlined, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barber.nombre,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onBackground,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Elegí el servicio y te mostramos quién está disponible',
                    style: TextStyle(fontSize: 12, color: tokens.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de barbero del equipo: foto + nombre + acción de agendar.
class _BarberCard extends StatelessWidget {
  final Barber barber;
  final VoidCallback onTap;
  const _BarberCard({required this.barber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: (barber.photoUrl?.isNotEmpty ?? false)
                    ? CachedNetworkImage(
                        imageUrl: barber.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: tokens.surfaceAlt),
                        errorWidget: (_, __, ___) => Container(
                          color: tokens.surfaceAlt,
                          child: Icon(Icons.person_outline,
                              size: 42, color: tokens.textSubtle),
                        ),
                      )
                    : Container(
                        color: tokens.surfaceAlt,
                        child: Icon(Icons.person_outline,
                            size: 42, color: tokens.textSubtle),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barber.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onBackground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 14, color: cs.primary),
                      const SizedBox(width: 5),
                      Text(
                        'Agendar cita',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
