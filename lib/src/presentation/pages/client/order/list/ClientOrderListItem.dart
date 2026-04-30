import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _kAccent  = Color(0xFF8B6F47);
const _kPrimary = Color(0xFF2D2D2D);
const _kSub     = Color(0xFF757575);

class ClientOrderListItem extends StatelessWidget {
  final Order order;
  const ClientOrderListItem(this.order, {super.key});

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
      return DateFormat('d MMM yyyy', 'es').format(dt);
    } catch (_) {
      return dt.toString().substring(0, 10);
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
    final color = _statusColor();
    final count = order.orderHasProducts?.length ?? 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
          context, 'client/order/detail', arguments: order),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pedido #${order.id}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(), size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        order.status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: _kSub),
                const SizedBox(width: 5),
                Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(fontSize: 12, color: _kSub),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.inventory_2_outlined, size: 13, color: _kSub),
                const SizedBox(width: 5),
                Text(
                  '$count producto${count != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: _kSub),
                ),
              ],
            ),
            if (order.address != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: _kSub),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order.address!.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kSub),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₡${fmtPrice(_total)}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kAccent),
                ),
                const Row(
                  children: [
                    Text('Ver detalle',
                        style: TextStyle(fontSize: 12, color: _kAccent)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: _kAccent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
