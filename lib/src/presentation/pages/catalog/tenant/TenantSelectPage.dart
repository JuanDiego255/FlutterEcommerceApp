import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ─── Tenant registry ─────────────────────────────────────────────────────────

class _Tenant {
  final String name;
  final String subtitle;
  final String location;
  final String domain;
  final IconData icon;
  final Color color;
  const _Tenant({
    required this.name,
    required this.subtitle,
    required this.location,
    required this.domain,
    required this.icon,
    required this.color,
  });
}

const _kTenants = [
  _Tenant(
    name: 'Mitai CR',
    subtitle: 'Ropa y accesorios para bebé',
    location: 'Grecia, Alajuela',
    domain: 'mitaicr.com',
    icon: Icons.child_care_outlined,
    color: Color(0xFFE91E8C),
  ),
  _Tenant(
    name: 'Mueblería Sarchi',
    subtitle: 'Muebles y decoración artesanal',
    location: 'Sarchí, Alajuela',
    domain: 'muebleriasarchi.com',
    icon: Icons.chair_outlined,
    color: Color(0xFF795548),
  ),
  _Tenant(
    name: 'Solo Ciclismo',
    subtitle: 'Equipos y accesorios de ciclismo',
    location: 'Guápiles, Limón',
    domain: 'solociclismocrc.safeworsolutions.com',
    icon: Icons.directions_bike_outlined,
    color: Color(0xFF1565C0),
  ),
  _Tenant(
    name: 'FUT Store',
    subtitle: 'Tienda de fútbol y deportes',
    location: 'Grecia, Alajuela',
    domain: 'futstorecr.safeworsolutions.com',
    icon: Icons.sports_soccer_outlined,
    color: Color(0xFF2E7D32),
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class TenantSelectPage extends StatefulWidget {
  const TenantSelectPage({super.key});

  @override
  State<TenantSelectPage> createState() => _TenantSelectPageState();
}

class _TenantSelectPageState extends State<TenantSelectPage> {
  _Tenant? _selected;
  bool _loading = false;

  Future<void> _enter() async {
    if (_selected == null || _loading) return;
    setState(() => _loading = true);
    await TenantSession.save(TenantConfig(domain: _selected!.domain));
    CartNotifier.instance.update(0);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'catalog/home');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDropdown(cs),
                    if (_selected != null) ...[
                      const SizedBox(height: 16),
                      _buildPreviewCard(_selected!, cs),
                      const SizedBox(height: 24),
                      _buildEnterButton(cs),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bg, const Color(0xFF1C1400), cs.primary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bienvenido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Seleccioná la tienda que querés explorar',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Dropdown ────────────────────────────────────────────────────────────

  Widget _buildDropdown(ColorScheme cs) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<_Tenant>(
            value: _selected,
            isExpanded: true,
            dropdownColor: cs.surface,
            hint: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Elegí una tienda...',
                style: TextStyle(color: tokens.textMuted, fontSize: 14),
              ),
            ),
            icon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: tokens.textMuted),
            ),
            borderRadius: BorderRadius.circular(14),
            items: _kTenants.map((t) {
              return DropdownMenuItem<_Tenant>(
                value: t,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: t.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(t.icon, color: t.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onBackground,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (t) => setState(() => _selected = t),
          ),
        ),
      ),
    );
  }

  // ─── Preview card ─────────────────────────────────────────────────────────

  Widget _buildPreviewCard(_Tenant t, ColorScheme cs) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(t.domain),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: t.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: t.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(t.icon, color: t.color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onBackground,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.subtitle,
                          style: TextStyle(fontSize: 13, color: tokens.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Text(
                              t.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.primary,
                                fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }

  // ─── Enter button ─────────────────────────────────────────────────────────

  Widget _buildEnterButton(ColorScheme cs) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _enter,
        child: _loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Entrar a ${_selected!.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }
}
