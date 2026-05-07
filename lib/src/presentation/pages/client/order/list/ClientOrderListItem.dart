import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClientOrderListItem extends StatelessWidget {
  final Order order;
  const ClientOrderListItem(this.order, {super.key});

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
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final color = _statusColor(cs, tokens);
    final count = order.orderHasProducts?.length ?? 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
          context, 'client/order/detail', arguments: order),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pedido #${order.id}',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: cs.onBackground),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
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
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: tokens.textMuted),
                const SizedBox(width: 5),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),
                const SizedBox(width: 16),
                Icon(Icons.inventory_2_outlined, size: 13, color: tokens.textMuted),
                const SizedBox(width: 5),
                Text(
                  '$count producto${count != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                ),
              ],
            ),
            if (order.address != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: tokens.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order.address!.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.textMuted),
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
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary),
                ),
                Row(
                  children: [
                    Text('Ver detalle',
                        style: TextStyle(fontSize: 12, color: cs.primary)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: cs.primary),
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
