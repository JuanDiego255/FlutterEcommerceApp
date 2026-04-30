import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _kAccent   = Color(0xFF8B6F47);
const _kPrimary  = Color(0xFF2D2D2D);
const _kSub      = Color(0xFF757575);
const _kDivider  = Color(0xFFEEEEEE);
const _kBg       = Color(0xFFFAFAFA);

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

  Color _statusColor() {
    switch (order.status) {
      case 'APROBADO':   return const Color(0xFF43A047);
      case 'DESPACHADO': return const Color(0xFF1E88E5);
      case 'CANCELADO':  return const Color(0xFFE53935);
      default:           return const Color(0xFFFF8F00);
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: Text(
          'Pedido #${order.id}',
          style: const TextStyle(
            color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildAddressCard(),
            const SizedBox(height: 16),
            _buildProductsCard(),
            const SizedBox(height: 16),
            _buildTotalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
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
                  style: const TextStyle(fontSize: 12, color: _kSub),
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

  Widget _buildAddressCard() {
    final addr = order.address;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined, color: _kAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Dirección de entrega',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _kDivider, height: 1),
          const SizedBox(height: 12),
          if (addr != null) ...[
            Text(
              addr.address,
              style: const TextStyle(fontSize: 14, color: _kPrimary, fontWeight: FontWeight.w500),
            ),
            if (addr.neighborhood.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                addr.neighborhood,
                style: const TextStyle(fontSize: 12, color: _kSub),
              ),
            ],
          ] else
            const Text(
              'Información de dirección no disponible',
              style: TextStyle(fontSize: 13, color: _kSub),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsCard() {
    final products = order.orderHasProducts ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Productos (${products.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _kDivider, height: 1),
          ...products.map((ohp) => _buildProductItem(ohp)),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderHasProduct ohp) {
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
                          Container(color: const Color(0xFFF5F5F5)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Icon(Icons.image_outlined,
                            color: Color(0xFFBDBDBD), size: 22),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(Icons.image_outlined,
                          color: Color(0xFFBDBDBD), size: 22),
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
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cantidad: ${ohp.quantity}  •  ₡${fmtPrice(ohp.product.effectivePrice)} c/u',
                  style: const TextStyle(fontSize: 11, color: _kSub),
                ),
              ],
            ),
          ),
          Text(
            '₡${fmtPrice(lineTotal)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal',
                  style: TextStyle(fontSize: 13, color: _kSub)),
              Text('₡${fmtPrice(_total)}',
                  style: const TextStyle(fontSize: 13, color: _kPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Envío', style: TextStyle(fontSize: 13, color: _kSub)),
              Text('A coordinar',
                  style: TextStyle(fontSize: 12, color: _kSub)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: _kDivider, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              Text(
                '₡${fmtPrice(_total)}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
