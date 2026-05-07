import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagState.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ClientShoppingBagItem extends StatelessWidget {
  final ClientShoppingBagBloc? bloc;
  final ClientShoppingBagState state;
  final Product? product;

  const ClientShoppingBagItem(this.bloc, this.state, this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final p = product;
    if (p == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(p, tokens),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(p, cs, tokens)),
            const SizedBox(width: 8),
            _buildPriceAndDelete(p, cs, tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Product p, AppTokens tokens) {
    final url = p.image1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 72,
        height: 80,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: tokens.surfaceAlt),
                errorWidget: (_, __, ___) => _placeholder(tokens),
              )
            : _placeholder(tokens),
      ),
    );
  }

  Widget _placeholder(AppTokens tokens) => Container(
        color: tokens.surfaceAlt,
        child: Center(child: Icon(Icons.image_outlined, color: tokens.textSubtle, size: 28)),
      );

  Widget _buildInfo(Product p, ColorScheme cs, AppTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onBackground),
        ),
        if (p.selectedVariant != null && p.selectedVariant!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: cs.primary.withOpacity(0.3)),
            ),
            child: Text(
              p.selectedVariant!,
              style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildQtyControls(p, cs, tokens),
      ],
    );
  }

  Widget _buildQtyControls(Product p, ColorScheme cs, AppTokens tokens) {
    final atLimit = p.isAtStockLimit;
    return Row(
      children: [
        _qtyBtn(icon: Icons.remove, onTap: () => bloc?.add(SubtractItem(product: p)), cs: cs, tokens: tokens),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: cs.outline),
          ),
          child: Text(
            '${p.quantity ?? 1}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onBackground),
          ),
        ),
        _qtyBtn(
          icon: Icons.add,
          onTap: atLimit ? null : () => bloc?.add(AddItem(product: p)),
          disabled: atLimit,
          cs: cs,
          tokens: tokens,
        ),
        if (atLimit)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text('máx', style: TextStyle(fontSize: 10, color: cs.error)),
          ),
      ],
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    VoidCallback? onTap,
    bool disabled = false,
    required ColorScheme cs,
    required AppTokens tokens,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled ? tokens.surfaceAlt : cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: cs.outline),
        ),
        child: Icon(
          icon,
          size: 15,
          color: disabled ? tokens.textSubtle : cs.onBackground,
        ),
      ),
    );
  }

  Widget _buildPriceAndDelete(Product p, ColorScheme cs, AppTokens tokens) {
    final lineTotal = p.effectivePrice * (p.quantity ?? 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₡${fmtPrice(lineTotal)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary),
        ),
        if (p.variantPrice != null && p.variantPrice! > 0) ...[
          const SizedBox(height: 2),
          Text(
            '₡${fmtPrice(p.effectivePrice)} c/u',
            style: TextStyle(fontSize: 10, color: tokens.textMuted),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => bloc?.add(RemoveItem(product: p)),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.delete_outline, color: cs.error, size: 18),
          ),
        ),
      ],
    );
  }
}
