import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagState.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _kAccent  = Color(0xFF8B6F47);
const _kPrimary = Color(0xFF2D2D2D);
const _kSub     = Color(0xFF757575);

class ClientShoppingBagBottomBar extends StatelessWidget {

  final ClientShoppingBagState state;

  const ClientShoppingBagBottomBar(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    if (state.products.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total del pedido',
                  style: TextStyle(fontSize: 13, color: _kSub),
                ),
                Text(
                  '₡${fmtPrice(state.total)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons row
            Row(
              children: [
                // Secondary: WhatsApp share (small icon button)
                Tooltip(
                  message: 'Enviar carrito por WhatsApp',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF25D366).withOpacity(0.35)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat_outlined,
                          color: Color(0xFF25D366), size: 20),
                      onPressed: () => _shareWhatsApp(context),
                      tooltip: 'Compartir por WhatsApp',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Primary: proceed to checkout
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                    label: const Text(
                      'Proceder al pago',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
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

  Future<void> _goToCheckout(BuildContext context) async {
    // Check if user is logged in
    final AuthResponse? session =
        await locator<AuthUseCases>().getUserSession.run();

    if (!context.mounted) return;

    if (session == null) {
      // Not logged in → show dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Iniciar sesión requerido',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: const Text(
              'Para continuar con tu pedido, inicia sesión o crea una cuenta.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, 'register');
              },
              child: const Text('Registrarse',
                  style: TextStyle(color: _kSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, 'login');
              },
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushNamed(context, 'client/address/list');
    }
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
