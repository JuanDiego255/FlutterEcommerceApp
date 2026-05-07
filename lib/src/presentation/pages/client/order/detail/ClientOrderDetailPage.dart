import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientOrderDetailPage extends StatelessWidget {
  const ClientOrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as Order;
    return _OrderDetailView(order: order);
  }
}

class _OrderDetailView extends StatelessWidget {
  final Order order;
  const _OrderDetailView({required this.order});

  Color _statusColor(ColorScheme cs, AppTokens tokens) {
    switch (order.status) {
      case 'APROBADO':   return tokens.success;
      case 'DESPACHADO': return cs.primary;
      case 'CANCELADO':  return cs.error;
      default:           return tokens.warning;
    }
  }

  IconData _statusIcon() {
    switch (order.status) {
      case 'APROBADO':   return Icons.check_circle_outline;
      case 'DESPACHADO': return Icons.local_shipping_outlined;
      case 'CANCELADO':  return Icons.cancel_outlined;
      default:           return Icons.hourglass_top_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'es').format(dt);
    } catch (_) {
      return dt.toString().substring(0, 16);
    }
  }

  double get _total {
    double t = 0;
    order.orderHasProducts?.forEach((ohp) {
      t += ohp.product.effectivePrice * ohp.quantity;
    });
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Pedido #${order.id}',
          style: TextStyle(
            color: cs.onBackground, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(cs, tokens),
            const SizedBox(height: 16),
            _buildAddressCard(cs, tokens),
            const SizedBox(height: 16),
            _buildProductsCard(cs, tokens),
            const SizedBox(height: 16),
            _buildTotalCard(cs, tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme cs, AppTokens tokens) {
    final color = _statusColor(cs, tokens);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(), color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '#${order.id}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ColorScheme cs, AppTokens tokens) {
    final addr = order.address;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Dirección de entrega',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onBackground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: cs.outline, height: 1),
          const SizedBox(height: 12),
          if (addr != null) ...[
            Text(
              addr.address,
              style: TextStyle(fontSize: 14, color: cs.onBackground, fontWeight: FontWeight.w500),
            ),
            if (addr.neighborhood.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                addr.neighborhood,
                style: TextStyle(fontSize: 12, color: tokens.textMuted),
              ),
            ],
          ] else
            Text(
              'Información de dirección no disponible',
              style: TextStyle(fontSize: 13, color: tokens.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(ColorScheme cs, AppTokens tokens) {
    final products = order.orderHasProducts ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Productos (${products.length})',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onBackground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: cs.outline, height: 1),
          ...products.map((ohp) => _buildProductItem(ohp, cs, tokens)),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderHasProduct ohp, ColorScheme cs, AppTokens tokens) {
    final url = ohp.product.image1;
    final lineTotal = ohp.product.effectivePrice * ohp.quantity;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 56,
              child: (url != null && url.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: tokens.surfaceAlt),
                      errorWidget: (_, __, ___) => Container(
                        color: tokens.surfaceAlt,
                        child: Icon(Icons.image_outlined,
                            color: tokens.textSubtle, size: 22),
                      ),
                    )
                  : Container(
                      color: tokens.surfaceAlt,
                      child: Icon(Icons.image_outlined,
                          color: tokens.textSubtle, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ohp.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: cs.onBackground),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cantidad: ${ohp.quantity}  •  ₡${fmtPrice(ohp.product.effectivePrice)} c/u',
                  style: TextStyle(fontSize: 11, color: tokens.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '₡${fmtPrice(lineTotal)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ColorScheme cs, AppTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal',
                  style: TextStyle(fontSize: 13, color: tokens.textMuted)),
              Text('₡${fmtPrice(_total)}',
                  style: TextStyle(fontSize: 13, color: cs.onBackground)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Envío', style: TextStyle(fontSize: 13, color: tokens.textMuted)),
              Text('A coordinar',
                  style: TextStyle(fontSize: 12, color: tokens.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: cs.outline, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onBackground),
              ),
              Text(
                '₡${fmtPrice(_total)}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: cs.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
