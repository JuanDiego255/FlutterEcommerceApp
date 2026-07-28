import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/TenantDirectoryService.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantOption.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:ecommerce_flutter/src/presentation/theme/theme_controller.dart';
import 'package:flutter/material.dart';

/// Selector de tiendas.
///
/// La lista es dinámica: viene del directorio central
/// (`GET /api/app/tenants`, tenants con app_enabled), con caché local y
/// lista de respaldo — ver [TenantDirectoryService].
class TenantSelectPage extends StatefulWidget {
  const TenantSelectPage({super.key});

  @override
  State<TenantSelectPage> createState() => _TenantSelectPageState();
}

class _TenantSelectPageState extends State<TenantSelectPage> {
  final TenantDirectoryService _directory = TenantDirectoryService();

  List<TenantOption>? _tenants;
  bool _fetchFailed = false;
  TenantOption? _selected;
  bool _useAsDefault = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() {
      _tenants = null;
      _selected = null;
      _fetchFailed = false;
    });
    try {
      final list = await _directory.fetch();
      if (!mounted) return;
      setState(() {
        _tenants = list;
        _fetchFailed = list.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tenants = [];
        _fetchFailed = true;
      });
    }
  }

  Future<void> _enter() async {
    final selected = _selected;
    if (selected == null || _loading) return;
    setState(() => _loading = true);

    // Cambio de tienda: limpiar credenciales y wishlist del tenant anterior
    // para no arrastrar sesión/estado de otra tienda.
    final changedTenant =
        TenantSession.isConfigured && TenantSession.host != selected.domain;
    if (changedTenant) {
      await SecureStorageService.clearAll();
    }

    await TenantSession.save(TenantConfig(
      domain: selected.domain,
      type: selected.type,
      colorHex: selected.colorHex,
      features: selected.features,
    ));
    await TenantSession.setDefaultEnabled(_useAsDefault);
    CartNotifier.instance.update(0);
    await WishlistNotifier.instance.reload();
    ThemeController.syncFromSession();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, TenantSession.homeRoute);
  }

  // ─── Presentación por tipo ──────────────────────────────────────────────

  IconData _iconFor(TenantOption t) =>
      t.isBarbershop ? Icons.content_cut : Icons.storefront_outlined;

  String _typeLabel(TenantOption t) =>
      t.isBarbershop ? 'Barbería' : 'Tienda en línea';

  Color _colorFor(TenantOption t, ColorScheme cs) {
    final hex = t.colorHex;
    if (hex != null && hex.isNotEmpty) {
      final cleaned = hex.replaceFirst('#', '');
      final value = int.tryParse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      if (value != null) return Color(value);
    }
    return cs.primary;
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
            Expanded(child: _buildBody(cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    final tokens = Theme.of(context).extension<AppTokens>()!;

    if (_tenants == null) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    if (_fetchFailed && _tenants!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: tokens.textSubtle),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el listado de tiendas',
              style: TextStyle(color: cs.onBackground, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Verificá tu conexión e intentá de nuevo',
              style: TextStyle(color: tokens.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadTenants,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropdown(cs),
          if (_selected != null) ...[
            const SizedBox(height: 16),
            _buildPreviewCard(_selected!, cs),
            const SizedBox(height: 12),
            _buildDefaultCheckbox(cs, tokens),
            const SizedBox(height: 16),
            _buildEnterButton(cs),
          ],
        ],
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
          child: DropdownButton<TenantOption>(
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
            items: _tenants!.map((t) {
              final color = _colorFor(t, cs);
              return DropdownMenuItem<TenantOption>(
                value: t,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_iconFor(t), color: color, size: 18),
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

  Widget _buildPreviewCard(TenantOption t, ColorScheme cs) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final color = _colorFor(t, cs);
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
                color: color,
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
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: t.logoUrl != null && t.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: t.logoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Icon(_iconFor(t), color: color, size: 30),
                            ),
                          )
                        : Icon(_iconFor(t), color: color, size: 30),
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
                          t.subtitle?.isNotEmpty ?? false
                              ? t.subtitle!
                              : _typeLabel(t),
                          style: TextStyle(fontSize: 13, color: tokens.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: color.withOpacity(0.35)),
                              ),
                              child: Text(
                                _typeLabel(t),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (t.location?.isNotEmpty ?? false) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: cs.primary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  t.location!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
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

  // ─── Default checkbox ─────────────────────────────────────────────────────

  Widget _buildDefaultCheckbox(ColorScheme cs, AppTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: CheckboxListTile(
        value: _useAsDefault,
        onChanged: (v) => setState(() => _useAsDefault = v ?? false),
        activeColor: cs.primary,
        checkColor: cs.onPrimary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(
          'Usar como tienda predeterminada',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onBackground,
          ),
        ),
        subtitle: Text(
          'Al abrir la app entrarás directo a esta tienda',
          style: TextStyle(fontSize: 12, color: tokens.textMuted),
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
                  Flexible(
                    child: Text(
                      'Entrar a ${_selected!.name}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }
}
