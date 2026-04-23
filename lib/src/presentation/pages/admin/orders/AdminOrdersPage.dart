import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/AdminOrder.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/orders/AdminOrderDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────
const Color _kBg      = Color(0xFFFAF8F5);
const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent  = Color(0xFFC8966A);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText    = Color(0xFF1A1A1A);
const Color _kSub     = Color(0xFF6B6B6B);

const Color _cVigente    = Color(0xFF22C55E);
const Color _cEntregado  = Color(0xFF3B82F6);
const Color _cCancelado  = Color(0xFFEF4444);
const Color _cPendCan    = Color(0xFFF59E0B);
const Color _cAprobado   = Color(0xFF14B8A6);
const Color _cListo      = Color(0xFF8B5CF6);
const Color _cWeb        = Color(0xFF3B82F6);
const Color _cInterna    = Color(0xFF22C55E);
const Color _cApartado   = Color(0xFFF97316);

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _api = MitaiApiService();
  final _fmt = NumberFormat('#,###', 'es');
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<AdminOrder> _orders = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _search = '';
  String _statusFilter = 'all'; // all | vigente | entregado | cancelado
  String _kindFilter = 'all';   // all | web | interna | apartado

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
          !_loadingMore && _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _orders = []; _currentPage = 1; _hasMore = true; });
    final result = await _api.getOrdersPaged(
      page: 1, search: _search, status: _statusFilter, kind: _kindFilter,
    );
    if (!mounted) return;
    if (result is Success<Map<String, dynamic>>) {
      final data = result.data['data'] as List<dynamic>? ?? [];
      final pag = result.data['pagination'] as Map<String, dynamic>? ?? {};
      setState(() {
        _orders = AdminOrder.fromJsonList(data);
        _currentPage = 1;
        _hasMore = (_currentPage < (pag['last_page'] as int? ?? 1));
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (result is Error<Map<String, dynamic>>) _snack(result.message);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _currentPage + 1;
    final result = await _api.getOrdersPaged(
      page: nextPage, search: _search, status: _statusFilter, kind: _kindFilter,
    );
    if (!mounted) return;
    if (result is Success<Map<String, dynamic>>) {
      final data = result.data['data'] as List<dynamic>? ?? [];
      final pag = result.data['pagination'] as Map<String, dynamic>? ?? {};
      setState(() {
        _orders.addAll(AdminOrder.fromJsonList(data));
        _currentPage = nextPage;
        _hasMore = (nextPage < (pag['last_page'] as int? ?? 1));
        _loadingMore = false;
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? _kPrimary : Colors.red.shade700,
    ));
  }

  void _setStatusFilter(String f) {
    if (_statusFilter == f) return;
    setState(() => _statusFilter = f);
    _load();
  }

  void _setKindFilter(String f) {
    if (_kindFilter == f) return;
    setState(() => _kindFilter = f);
    _load();
  }

  // ─── Toggle actions ───────────────────────────────────────────────────────

  Future<void> _toggleApprove(int index) async {
    final order = _orders[index];
    final result = await _api.toggleOrderApprove(order.id);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _orders[index] = order.copyWith(approved: result.data));
    } else if (result is Error<int>) {
      _snack(result.message);
    }
  }

  Future<void> _toggleDelivery(int index) async {
    final order = _orders[index];
    final result = await _api.toggleOrderDelivery(order.id);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _orders[index] = order.copyWith(delivered: result.data));
      _snack('Entrega actualizada', ok: true);
    } else if (result is Error<int>) {
      _snack(result.message);
    }
  }

  Future<void> _toggleReady(int index) async {
    final order = _orders[index];
    final result = await _api.toggleOrderReady(order.id);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _orders[index] = order.copyWith(readyToGive: result.data));
    } else if (result is Error<int>) {
      _snack(result.message);
    }
  }

  Future<void> _showCancelDialog(int index) async {
    final order = _orders[index];
    int? chosen;

    if (order.cancelBuy == 0) {
      chosen = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancelar pedido'),
          content: const Text('¿Cómo deseas proceder con este pedido?'),
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
    } else if (order.cancelBuy == 1) {
      chosen = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('En proceso de cancelación'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 0),
              child: const Text('Reactivar', style: TextStyle(color: _cVigente)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 2),
              style: ElevatedButton.styleFrom(backgroundColor: _cCancelado),
              child: const Text('Confirmar cancelación', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      chosen = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pedido cancelado'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
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
    final result = await _api.updateOrderCancel(order.id, chosen);
    if (!mounted) return;
    if (result is Success<int>) {
      setState(() => _orders[index] = order.copyWith(cancelBuy: result.data));
      _snack(_cancelLabel(result.data), ok: true);
    } else if (result is Error<int>) {
      _snack(result.message);
    }
  }

  Future<void> _confirmDelete(int index) async {
    final order = _orders[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar pedido #${order.id}'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await _api.deleteOrder(order.id);
    if (!mounted) return;
    if (result is Success<bool>) {
      setState(() => _orders.removeAt(index));
      _snack('Pedido eliminado', ok: true);
    } else if (result is Error<bool>) {
      _snack(result.message);
    }
  }

  // ─── Quick-view sheets ────────────────────────────────────────────────────

  Future<void> _showShippingSheet(AdminOrder order) async {
    final result = await _api.getOrderQuickInfo(order.id);
    if (!mounted) return;
    if (result is Error<Map<String, dynamic>>) {
      _snack(result.message);
      return;
    }
    final data = (result as Success<Map<String, dynamic>>).data;
    final ship = data['shipping'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ShippingSheet(orderId: order.id, shipping: ship),
    );
  }

  Future<void> _showItemsSheet(AdminOrder order) async {
    final result = await _api.getOrderQuickInfo(order.id);
    if (!mounted) return;
    if (result is Error<Map<String, dynamic>>) {
      _snack(result.message);
      return;
    }
    final data = (result as Success<Map<String, dynamic>>).data;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => AdminOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ItemsSheet(orderId: order.id, items: items, fmt: _fmt),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterBar(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          if (v.length >= 2 || v.isEmpty) {
            _search = v;
            _load();
          }
        },
        onSubmitted: (v) { _search = v; _load(); },
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, teléfono, correo…',
          hintStyle: const TextStyle(color: _kSub, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _kSub, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _kSub),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search = '';
                    _load();
                  })
              : null,
          filled: true,
          fillColor: _kBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _DropFilter(
              icon: Icons.flag_outlined,
              value: _statusFilter,
              items: const [
                ('all',       'Todos los estados'),
                ('pendiente', 'Pendientes'),
                ('vigente',   'Vigentes'),
                ('entregado', 'Entregados'),
                ('cancelado', 'Cancelados'),
              ],
              onChanged: _setStatusFilter,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DropFilter(
              icon: Icons.tune_outlined,
              value: _kindFilter,
              items: const [
                ('all',       'Cualquier tipo'),
                ('web',       'Web'),
                ('interna',   'Interna'),
                ('apartado',  'Apartado'),
              ],
              onChanged: _setKindFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: _kAccent),
            const SizedBox(height: 12),
            const Text('Sin pedidos', style: TextStyle(color: _kSub, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Recargar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _orders.length + (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _orders.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)),
            );
          }
          return _OrderCard(
            order: _orders[i],
            index: i,
            fmt: _fmt,
            onApprove: () => _toggleApprove(i),
            onDelivery: () => _toggleDelivery(i),
            onReady: () => _toggleReady(i),
            onCancel: () => _showCancelDialog(i),
            onDelete: () => _confirmDelete(i),
            onShipping: () => _showShippingSheet(_orders[i]),
            onItems: () => _showItemsSheet(_orders[i]),
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminOrderDetailPage(order: _orders[i]),
                ),
              );
              if (changed == true && mounted) _load();
            },
          );
        },
      ),
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final int index;
  final NumberFormat fmt;
  final VoidCallback onApprove;
  final VoidCallback onDelivery;
  final VoidCallback onReady;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onShipping;
  final VoidCallback onItems;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.index,
    required this.fmt,
    required this.onApprove,
    required this.onDelivery,
    required this.onReady,
    required this.onCancel,
    required this.onDelete,
    required this.onShipping,
    required this.onItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: order.cancelBuy == 2
              ? Border.all(color: _cCancelado.withOpacity(0.3))
              : order.cancelBuy == 1
                  ? Border.all(color: _cPendCan.withOpacity(0.4))
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildCustomer(),
            _buildTotals(),
            const Divider(height: 1, color: Color(0xFFF0EBE3)),
            _buildStatusPills(),
            const Divider(height: 1, color: Color(0xFFF0EBE3)),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          Text('#${order.id}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _kText)),
          const SizedBox(width: 8),
          _KindChip(origin: order.origin),
          const Spacer(),
          Text(order.formattedDate,
              style: const TextStyle(fontSize: 11, color: _kSub)),
        ],
      ),
    );
  }

  Widget _buildCustomer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kText)),
          if (order.displayTelephone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                const Icon(Icons.phone_outlined, size: 12, color: _kSub),
                const SizedBox(width: 4),
                Text(order.displayTelephone, style: const TextStyle(fontSize: 12, color: _kSub)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TotalChip(label: 'Total', amount: order.totalBuy, fmt: fmt),
          const SizedBox(width: 10),
          if (order.totalDelivery > 0) ...[
            _TotalChip(label: 'Envío', amount: order.totalDelivery, fmt: fmt),
            const SizedBox(width: 10),
          ],
          if (order.apartado == 1 && order.pendiente > 0)
            _TotalChip(
                label: 'Pendiente', amount: order.pendiente, fmt: fmt, highlight: true),
        ],
      ),
    );
  }

  Widget _buildStatusPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _StatusPill(
            label: _cancelLabel(order.cancelBuy),
            color: _cancelColor(order.cancelBuy),
          ),
          if (order.approved == 1)
            const _StatusPill(label: 'Aprobado', color: _cAprobado),
          if (order.readyToGive == 1)
            const _StatusPill(label: 'Listo', color: _cListo),
          if (order.delivered == 1)
            const _StatusPill(label: 'Entregado', color: _cEntregado),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.local_shipping_outlined,
            tooltip: 'Info envío',
            color: _cEntregado,
            onTap: onShipping,
          ),
          _ActionBtn(
            icon: Icons.shopping_bag_outlined,
            tooltip: 'Artículos',
            color: _cVigente,
            onTap: onItems,
          ),
          const Spacer(),
          _ActionBtn(
            icon: Icons.inventory_2_outlined,
            tooltip: order.readyToGive == 1 ? 'Marcar no listo' : 'Marcar listo',
            color: order.readyToGive == 1 ? _cListo : _kSub,
            onTap: onReady,
          ),
          _ActionBtn(
            icon: Icons.delivery_dining_outlined,
            tooltip: order.delivered == 1 ? 'Quitar entregado' : 'Marcar entregado',
            color: order.delivered == 1 ? _cEntregado : _kSub,
            onTap: onDelivery,
          ),
          _ActionBtn(
            icon: Icons.check_circle_outline,
            tooltip: order.approved == 1 ? 'Quitar aprobación' : 'Aprobar',
            color: order.approved == 1 ? _cAprobado : _kSub,
            onTap: onApprove,
          ),
          _ActionBtn(
            icon: Icons.block_outlined,
            tooltip: 'Cancelar',
            color: _cPendCan,
            onTap: onCancel,
          ),
          _ActionBtn(
            icon: Icons.delete_outline,
            tooltip: 'Eliminar',
            color: _cCancelado,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Helpers & small widgets ──────────────────────────────────────────────────

String _cancelLabel(int v) {
  switch (v) {
    case 1: return 'En cancelación';
    case 2: return 'Cancelado';
    default: return 'Vigente';
  }
}

Color _cancelColor(int v) {
  switch (v) {
    case 1: return _cPendCan;
    case 2: return _cCancelado;
    default: return _cVigente;
  }
}

class _KindChip extends StatelessWidget {
  final String origin;
  const _KindChip({required this.origin});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (origin) {
      case 'Web':      color = _cWeb;      break;
      case 'Apartado': color = _cApartado; break;
      default:         color = _cInterna;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(origin,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final double amount;
  final NumberFormat fmt;
  final bool highlight;
  const _TotalChip(
      {required this.label, required this.amount, required this.fmt, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _kSub)),
        Text('₡${fmt.format(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? _cApartado : _kText,
            )),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.tooltip, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _DropFilter extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<(String, String)> items;
  final void Function(String) onChanged;
  const _DropFilter(
      {required this.icon, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = value != 'all';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: active ? _kPrimary.withOpacity(0.07) : _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? _kPrimary.withOpacity(0.5) : const Color(0xFFD6C9B8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18,
              color: active ? _kPrimary : _kSub),
          style: TextStyle(fontSize: 12, color: active ? _kPrimary : _kText,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500),
          onChanged: (v) { if (v != null) onChanged(v); },
          items: items.map((item) {
            final val = item.$1;
            final label = item.$2;
            final isSelected = val == value;
            return DropdownMenuItem<String>(
              value: val,
              child: Row(
                children: [
                  Icon(icon, size: 13, color: isSelected ? _kPrimary : _kSub),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? _kPrimary : _kText,
                        )),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Shipping info bottom sheet ───────────────────────────────────────────────

class _ShippingSheet extends StatelessWidget {
  final int orderId;
  final Map<String, dynamic> shipping;
  const _ShippingSheet({required this.orderId, required this.shipping});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cEntregado.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_outlined, color: _cEntregado, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Información de envío',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _kText)),
                    Text('Pedido #$orderId',
                        style: const TextStyle(fontSize: 12, color: _kSub)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: _kSub),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _twoCol('NOMBRE', shipping['name'] ?? '—', 'TELÉFONO', shipping['telephone'] ?? '—'),
          const SizedBox(height: 14),
          _field('E-MAIL', shipping['email'] ?? '—'),
          const Divider(height: 28, color: Color(0xFFF0EBE3)),
          _twoCol('PAÍS', shipping['country'] ?? '—', 'PROVINCIA', shipping['province'] ?? '—'),
          const SizedBox(height: 14),
          _twoCol('CANTÓN', shipping['city'] ?? '—', 'DISTRITO', shipping['district'] ?? '—'),
          const SizedBox(height: 14),
          _field('DIRECCIÓN', shipping['address'] ?? '—'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _twoCol(String l1, String v1, String l2, String v2) => Row(
    children: [
      Expanded(child: _field(l1, v1)),
      const SizedBox(width: 16),
      Expanded(child: _field(l2, v2)),
    ],
  );

  Widget _field(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: _kSub, fontWeight: FontWeight.w600,
          letterSpacing: 0.5)),
      const SizedBox(height: 3),
      Text(value.isEmpty ? '—' : value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
    ],
  );
}

// ─── Items bottom sheet ───────────────────────────────────────────────────────

class _ItemsSheet extends StatelessWidget {
  final int orderId;
  final List<AdminOrderItem> items;
  final NumberFormat fmt;
  const _ItemsSheet({required this.orderId, required this.items, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (ctx, sc) => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _cVigente.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: _cVigente, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Artículos del pedido',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _kText)),
                      Text('Pedido #$orderId',
                          style: const TextStyle(fontSize: 12, color: _kSub)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _kSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0EBE3)),
              itemBuilder: (_, i) => _ItemRow(item: items[i], fmt: fmt),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final AdminOrderItem item;
  final NumberFormat fmt;
  const _ItemRow({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 60, height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imgPlaceholder(),
                    errorWidget: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
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
                    style: const TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('CANTIDAD',
                  style: TextStyle(fontSize: 9, color: _kSub, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Text('${item.quantity}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBE3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.shopping_bag_outlined, color: _kAccent, size: 24),
      );
}
