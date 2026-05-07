import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/AdminOrder.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Semantic status colors (business-logic — do NOT replace) ─────────────────
const Color _cVigente   = Color(0xFF22C55E);
const Color _cEntregado = Color(0xFF3B82F6);
const Color _cCancelado = Color(0xFFEF4444);
const Color _cPendCan   = Color(0xFFF59E0B);
const Color _cAprobado  = Color(0xFF14B8A6);
const Color _cListo     = Color(0xFF8B5CF6);
const Color _cApartado  = Color(0xFFF97316);

class AdminOrderDetailPage extends StatefulWidget {
  final AdminOrder order;
  const AdminOrderDetailPage({super.key, required this.order});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  final _api = MitaiApiService();
  final _fmt = NumberFormat('#,###', 'es');
  final _guideCtrl = TextEditingController();
  final _noteCtrl  = TextEditingController();

  late AdminOrder _order;
  bool _loading = true;
  bool _savingGuide = false;
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _guideCtrl.text = _order.guideNumber ?? '';
    _noteCtrl.text  = _order.detail ?? '';
    _loadDetail();
  }

  @override
  void dispose() {
    _guideCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final result = await _api.getOrderDetail(_order.id);
    if (!mounted) return;
    if (result is Success<AdminOrder>) {
      setState(() {
        _order = result.data;
        _guideCtrl.text = _order.guideNumber ?? '';
        _noteCtrl.text  = _order.detail ?? '';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? cs.primary : cs.error,
    ));
  }

  // ─── Status toggles ─────────────────────────────────────────────────────────

  Future<void> _toggleApprove() async {
    final result = await _api.toggleOrderApprove(_order.id);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _order = _order.copyWith(approved: result.data));
      _snack('Aprobación actualizada', ok: true);
    } else if (result is Error<int>) { _snack(result.message); }
  }

  Future<void> _toggleDelivery() async {
    final result = await _api.toggleOrderDelivery(_order.id);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _order = _order.copyWith(delivered: result.data));
      _snack('Entrega actualizada', ok: true);
    } else if (result is Error<int>) { _snack(result.message); }
  }

  Future<void> _toggleReady() async {
    final result = await _api.toggleOrderReady(_order.id);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _order = _order.copyWith(readyToGive: result.data));
      _snack('Estado actualizado', ok: true);
    } else if (result is Error<int>) { _snack(result.message); }
  }

  Future<void> _showCancelDialog() async {
    int? chosen;
    if (_order.cancelBuy == 0) {
      chosen = await showDialog<int>(
        context: context,
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Cancelar pedido', style: TextStyle(color: cs.onBackground)),
            content: Text('¿Cómo deseas proceder?',
                style: TextStyle(color: Theme.of(ctx).extension<AppTokens>()!.textMuted)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 1),
                child: const Text('Iniciar cancelación', style: TextStyle(color: _cPendCan)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 2),
                style: ElevatedButton.styleFrom(backgroundColor: _cCancelado),
                child: const Text('Cancelar ahora', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } else {
      chosen = await showDialog<int>(
        context: context,
        builder: (ctx) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              _order.cancelBuy == 1 ? 'En proceso de cancelación' : 'Pedido cancelado',
              style: TextStyle(color: cs.onBackground),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
              if (_order.cancelBuy == 1)
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, 2),
                  style: ElevatedButton.styleFrom(backgroundColor: _cCancelado),
                  child: const Text('Confirmar cancelación', style: TextStyle(color: Colors.white)),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 0),
                style: ElevatedButton.styleFrom(backgroundColor: _cVigente),
                child: const Text('Reactivar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
    if (chosen == null || !mounted) return;
    final result = await _api.updateOrderCancel(_order.id, chosen);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _order = _order.copyWith(cancelBuy: result.data));
      _snack('Estado actualizado', ok: true);
    } else if (result is Error<int>) { _snack(result.message); }
  }

  // ─── Guide + Note saves ──────────────────────────────────────────────────────

  Future<void> _saveGuide() async {
    final val = _guideCtrl.text.trim();
    setState(() => _savingGuide = true);
    final result = await _api.updateOrderGuideNumber(_order.id, val);
    if (!mounted) return;
    setState(() => _savingGuide = false);
    if (result is Success<String>) {
      setState(() => _order = _order.copyWith(guideNumber: result.data, delivered: 1));
      _snack('Número de guía guardado', ok: true);
    } else if (result is Error<String>) { _snack(result.message); }
  }

  Future<void> _saveNote() async {
    final val = _noteCtrl.text.trim();
    setState(() => _savingNote = true);
    final result = await _api.updateOrderNote(_order.id, val);
    if (!mounted) return;
    setState(() => _savingNote = false);
    if (result is Success<bool>) {
      setState(() => _order = _order.copyWith(detail: val));
      _snack('Nota guardada', ok: true);
    } else if (result is Error<bool>) { _snack(result.message); }
  }

  // ─── Abono ───────────────────────────────────────────────────────────────────

  Future<void> _showAbonoDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tokens = Theme.of(ctx).extension<AppTokens>()!;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Registrar abono', style: TextStyle(color: cs.onBackground)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pendiente: ₡${_fmt.format(_order.pendiente)}',
                  style: const TextStyle(color: _cApartado, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Monto del abono',
                  labelStyle: TextStyle(color: tokens.textMuted),
                  prefixText: '₡ ',
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final monto = double.tryParse(ctrl.text.replaceAll(',', '').trim()) ?? 0;
    if (monto <= 0) return;
    final result = await _api.addOrderAbono(_order.id, monto);
    if (!mounted) return;
    if (result is Success<double>) {
      setState(() => _order = _order.copyWith(montoApartado: result.data));
      _snack('Abono registrado', ok: true);
    } else if (result is Error<double>) { _snack(result.message); }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        elevation: 0,
        title: Text('Pedido #${_order.id}',
            style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.primary),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _buildBody(),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildOrderInfoCard(),
        const SizedBox(height: 12),
        _buildCustomerCard(),
        const SizedBox(height: 12),
        if (_hasShipping()) ...[
          _buildShippingCard(),
          const SizedBox(height: 12),
        ],
        _buildItemsSection(),
        const SizedBox(height: 12),
        _buildGuideSection(),
        const SizedBox(height: 12),
        _buildNoteSection(),
        if (_order.apartado == 1) ...[
          const SizedBox(height: 12),
          _buildAbonoSection(),
        ],
      ],
    );
  }

  // ─── Cards ──────────────────────────────────────────────────────────────────

  Widget _buildOrderInfoCard() {
    final cs = Theme.of(context).colorScheme;
    return _Card(
      child: Column(
        children: [
          _InfoRow(
            label: 'Origen',
            value: _order.origin,
            isFirst: true,
            trailing: _kindBadge(_order.origin),
          ),
          _InfoRow(label: 'Fecha', value: _order.formattedDate),
          _InfoRow(label: 'Estado',
              value: '',
              trailing: _cancelBadge(_order.cancelBuy)),
          _InfoRow(label: 'Total',
              value: '₡${_fmt.format(_order.totalBuy)}',
              valueStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.primary)),
          if (_order.totalDelivery > 0)
            _InfoRow(label: 'Envío', value: '₡${_fmt.format(_order.totalDelivery)}'),
          if (_order.totalIva > 0)
            _InfoRow(label: 'IVA', value: '₡${_fmt.format(_order.totalIva)}'),
          if (_order.guideNumber != null && _order.guideNumber!.isNotEmpty)
            _InfoRow(label: 'Guía', value: _order.guideNumber!),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _SectionCard(
      icon: Icons.person_outline,
      title: 'Cliente',
      child: Column(
        children: [
          _InfoRow(label: 'Nombre', value: _order.displayName, isFirst: true),
          if (_order.displayTelephone.isNotEmpty)
            _InfoRow(label: 'Teléfono', value: _order.displayTelephone),
          if (_order.displayEmail.isNotEmpty)
            _InfoRow(label: 'Correo', value: _order.displayEmail),
        ],
      ),
    );
  }

  bool _hasShipping() =>
      [_order.sAddress, _order.sCity, _order.sProvince, _order.sCountry]
          .any((v) => v != null && v.isNotEmpty);

  Widget _buildShippingCard() {
    return _SectionCard(
      icon: Icons.local_shipping_outlined,
      iconColor: _cEntregado,
      title: 'Dirección de envío',
      child: Column(
        children: [
          if (_order.sCountry?.isNotEmpty == true)
            _InfoRow(label: 'País', value: _order.sCountry!, isFirst: true),
          if (_order.sProvince?.isNotEmpty == true)
            _InfoRow(label: 'Provincia', value: _order.sProvince!),
          if (_order.sCity?.isNotEmpty == true)
            _InfoRow(label: 'Cantón', value: _order.sCity!),
          if (_order.sDistrict?.isNotEmpty == true)
            _InfoRow(label: 'Distrito', value: _order.sDistrict!),
          if (_order.sAddress?.isNotEmpty == true)
            _InfoRow(label: 'Dirección', value: _order.sAddress!),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return _SectionCard(
      icon: Icons.shopping_bag_outlined,
      iconColor: _cVigente,
      title: 'Artículos (${_order.items.length})',
      child: _order.items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sin artículos', style: TextStyle(color: tokens.textMuted)),
            )
          : Column(
              children: List.generate(_order.items.length, (i) {
                final item = _order.items[i];
                return _ItemDetailRow(item: item, fmt: _fmt, isLast: i == _order.items.length - 1);
              }),
            ),
    );
  }

  Widget _buildGuideSection() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return _SectionCard(
      icon: Icons.pin_outlined,
      title: 'Número de guía',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _guideCtrl,
                decoration: InputDecoration(
                  hintText: 'Ej. CR123456789',
                  hintStyle: TextStyle(color: tokens.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _savingGuide ? null : _saveGuide,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _savingGuide
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return _SectionCard(
      icon: Icons.notes_outlined,
      title: 'Nota del pedido',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Agregar una nota interna…',
                hintStyle: TextStyle(color: tokens.textMuted, fontSize: 13),
                filled: true,
                fillColor: cs.surface,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingNote ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _savingNote
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar nota'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbonoSection() {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final total     = _order.totalBuy;
    final pagado    = _order.montoApartado;
    final pendiente = _order.pendiente;
    final pct       = total > 0 ? (pagado / total).clamp(0.0, 1.0) : 0.0;

    return _SectionCard(
      icon: Icons.payments_outlined,
      iconColor: _cApartado,
      title: 'Apartado — pagos',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AbonoStat(label: 'Total', value: total, fmt: _fmt),
                const SizedBox(width: 20),
                _AbonoStat(label: 'Pagado', value: pagado, fmt: _fmt, color: _cVigente),
                const SizedBox(width: 20),
                _AbonoStat(label: 'Pendiente', value: pendiente, fmt: _fmt,
                    color: pendiente > 0 ? _cApartado : _cVigente),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.outline,
                color: pendiente > 0 ? _cApartado : _cVigente,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(pct * 100).toStringAsFixed(0)}% pagado',
                style: TextStyle(fontSize: 11, color: tokens.textMuted)),
            if (pendiente > 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAbonoDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cApartado,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Registrar abono', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Bottom action bar ───────────────────────────────────────────────────────

  Widget _buildActionBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _ActionToggle(
              icon: Icons.check_circle_outline,
              activeIcon: Icons.check_circle,
              label: 'Aprobar',
              active: _order.approved == 1,
              activeColor: _cAprobado,
              onTap: _toggleApprove,
            ),
            const SizedBox(width: 8),
            _ActionToggle(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              label: 'Listo',
              active: _order.readyToGive == 1,
              activeColor: _cListo,
              onTap: _toggleReady,
            ),
            const SizedBox(width: 8),
            _ActionToggle(
              icon: Icons.delivery_dining_outlined,
              activeIcon: Icons.delivery_dining,
              label: 'Entregado',
              active: _order.delivered == 1,
              activeColor: _cEntregado,
              onTap: _toggleDelivery,
            ),
            const SizedBox(width: 8),
            _ActionToggle(
              icon: Icons.block_outlined,
              activeIcon: Icons.block,
              label: 'Cancelar',
              active: _order.cancelBuy > 0,
              activeColor: _cCancelado,
              onTap: _showCancelDialog,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Badge helpers ──────────────────────────────────────────────────────────

  Widget _kindBadge(String origin) {
    Color color;
    switch (origin) {
      case 'Web':      color = const Color(0xFF3B82F6); break;
      case 'Apartado': color = _cApartado;               break;
      default:         color = _cVigente;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(origin,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _cancelBadge(int v) {
    Color color;
    String label;
    switch (v) {
      case 1:
        color = _cPendCan; label = 'En cancelación'; break;
      case 2:
        color = _cCancelado; label = 'Cancelado'; break;
      default:
        color = _cVigente; label = 'Vigente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor ?? cs.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onBackground)),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFirst;
  final Widget? trailing;
  final TextStyle? valueStyle;
  const _InfoRow({required this.label, required this.value, this.isFirst = false,
      this.trailing, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? BorderSide.none : BorderSide(color: cs.outline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: tokens.textMuted)),
          trailing ??
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: valueStyle ??
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onBackground)),
              ),
        ],
      ),
    );
  }
}

class _ItemDetailRow extends StatelessWidget {
  final AdminOrderItem item;
  final NumberFormat fmt;
  final bool isLast;
  const _ItemDetailRow({required this.item, required this.fmt, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 64, height: 64, fit: BoxFit.cover,
                    placeholder: (_, __) => _imgPh(tokens),
                    errorWidget: (_, __, ___) => _imgPh(tokens),
                  )
                : _imgPh(tokens),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onBackground)),
                if (item.attributes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4, runSpacing: 4,
                      children: item.attributes
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.outline,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(a, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 6),
                Text('₡${fmt.format(item.total)}',
                    style: TextStyle(fontSize: 14, color: cs.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('CANT', style: TextStyle(fontSize: 9, color: tokens.textMuted,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text('${item.quantity}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onBackground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgPh(AppTokens tokens) => Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: tokens.surfaceAlt, borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.shopping_bag_outlined, color: tokens.textSubtle, size: 26),
      );
}

class _AbonoStat extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat fmt;
  final Color? color;
  const _AbonoStat({required this.label, required this.value, required this.fmt, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
        Text('₡${fmt.format(value)}',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: color ?? cs.onBackground)),
      ],
    );
  }
}

class _ActionToggle extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _ActionToggle({
    required this.icon, required this.activeIcon, required this.label,
    required this.active, required this.activeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? activeColor.withOpacity(0.12) : cs.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? activeColor.withOpacity(0.4) : cs.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon,
                  size: 20, color: active ? activeColor : tokens.textMuted),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: active ? activeColor : tokens.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
