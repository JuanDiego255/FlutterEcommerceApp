import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/AdminOrder.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────
const Color _kBg      = Color(0xFFFAF8F5);
const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent  = Color(0xFFC8966A);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText    = Color(0xFF1A1A1A);
const Color _kSub     = Color(0xFF6B6B6B);
const Color _kDivider = Color(0xFFF0EBE3);

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? _kPrimary : Colors.red.shade700,
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
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancelar pedido'),
          content: const Text('¿Cómo deseas proceder?'),
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
        ),
      );
    } else {
      chosen = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(_order.cancelBuy == 1 ? 'En proceso de cancelación' : 'Pedido cancelado'),
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
        ),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Registrar abono'),
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
              decoration: const InputDecoration(
                labelText: 'Monto del abono',
                prefixText: '₡ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text('Pedido #${_order.id}',
            style: const TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: _kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimary),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
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
              valueStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimary)),
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
    return _SectionCard(
      icon: Icons.shopping_bag_outlined,
      iconColor: _cVigente,
      title: 'Artículos (${_order.items.length})',
      child: _order.items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin artículos', style: TextStyle(color: _kSub)),
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
                  hintStyle: const TextStyle(color: _kSub, fontSize: 13),
                  filled: true,
                  fillColor: _kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _savingGuide ? null : _saveGuide,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _savingGuide
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
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
                hintStyle: const TextStyle(color: _kSub, fontSize: 13),
                filled: true,
                fillColor: _kBg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingNote ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _savingNote
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar nota', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbonoSection() {
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
                backgroundColor: const Color(0xFFF0EBE3),
                color: pendiente > 0 ? _cApartado : _cVigente,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(pct * 100).toStringAsFixed(0)}% pagado',
                style: const TextStyle(fontSize: 11, color: _kSub)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, -2))],
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: iconColor ?? _kPrimary),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kText)),
                ],
              ),
            ),
            const Divider(height: 1, color: _kDivider),
            child,
          ],
        ),
      );
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            top: isFirst ? BorderSide.none : const BorderSide(color: _kDivider, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: _kSub)),
            trailing ??
                Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: valueStyle ??
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
                ),
          ],
        ),
      );
}

class _ItemDetailRow extends StatelessWidget {
  final AdminOrderItem item;
  final NumberFormat fmt;
  final bool isLast;
  const _ItemDetailRow({required this.item, required this.fmt, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _kDivider, width: 1)),
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
                    placeholder: (_, __) => _imgPh(),
                    errorWidget: (_, __, ___) => _imgPh(),
                  )
                : _imgPh(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kText)),
                if (item.attributes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4, runSpacing: 4,
                      children: item.attributes
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0EBE3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(a, style: const TextStyle(fontSize: 11, color: _kSub)),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 6),
                Text('₡${fmt.format(item.total)}',
                    style: const TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('CANT', style: TextStyle(fontSize: 9, color: _kSub,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text('${item.quantity}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgPh() => Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: const Color(0xFFF0EBE3), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.shopping_bag_outlined, color: _kAccent, size: 26),
      );
}

class _AbonoStat extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat fmt;
  final Color? color;
  const _AbonoStat({required this.label, required this.value, required this.fmt, this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _kSub)),
          Text('₡${fmt.format(value)}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: color ?? _kText)),
        ],
      );
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
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? activeColor.withOpacity(0.12) : _kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: active ? activeColor.withOpacity(0.4) : const Color(0xFFE8DDD3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? activeIcon : icon,
                    size: 20, color: active ? activeColor : _kSub),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: active ? activeColor : _kSub)),
              ],
            ),
          ),
        ),
      );
}
