import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagState.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientShoppingBagBottomBar extends StatelessWidget {
  final ClientShoppingBagState state;

  const ClientShoppingBagBottomBar(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    if (state.products.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: cs.background,
          border: Border(top: BorderSide(color: cs.outline)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total del pedido', style: TextStyle(fontSize: 13, color: tokens.textMuted)),
                Text(
                  '₡${fmtPrice(state.total)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Tooltip(
                  message: 'Enviar carrito por WhatsApp',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF25D366).withOpacity(0.35)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20),
                      onPressed: () => _shareWhatsApp(context),
                      tooltip: 'Compartir por WhatsApp',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                    label: const Text('Proceder al pago', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    onPressed: () => _goToCheckout(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToCheckout(BuildContext context) {
    Navigator.pushNamed(context, 'checkout/guest');
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final lines = state.products.map((p) {
      final variant = p.selectedVariant != null ? ' (${p.selectedVariant})' : '';
      return '• ${p.name}$variant x${p.quantity} → ₡${fmtPrice(p.effectivePrice * (p.quantity ?? 1))}';
    }).join('\n');

    final text = Uri.encodeComponent(
      '🛒 *Mi pedido*\n$lines\n\n*Total: ₡${fmtPrice(state.total)}*',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
