import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagState.dart';
import 'package:flutter/material.dart';

const _kAccent  = Color(0xFF8B6F47);
const _kPrimary = Color(0xFF2D2D2D);
const _kSub     = Color(0xFF757575);
const _kDivider = Color(0xFFEEEEEE);

class ClientShoppingBagItem extends StatelessWidget {

  final ClientShoppingBagBloc? bloc;
  final ClientShoppingBagState state;
  final Product? product;

  const ClientShoppingBagItem(this.bloc, this.state, this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = product;
    if (p == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(p),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(p)),
            const SizedBox(width: 8),
            _buildPriceAndDelete(p),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Product p) {
    final url = p.image1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        height: 80,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF5F5F5),
    child: const Center(child: Icon(Icons.image_outlined, color: Color(0xFFBDBDBD), size: 28)),
  );

  Widget _buildInfo(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
        if (p.selectedVariant != null && p.selectedVariant!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kAccent.withOpacity(0.3)),
            ),
            child: Text(
              p.selectedVariant!,
              style: const TextStyle(fontSize: 10, color: _kAccent, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildQtyControls(p),
      ],
    );
  }

  Widget _buildQtyControls(Product p) {
    final atLimit = p.isAtStockLimit;
    return Row(
      children: [
        _qtyBtn(
          icon: Icons.remove,
          onTap: () => bloc?.add(SubtractItem(product: p)),
        ),
        Container(
          width: 32,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${p.quantity ?? 1}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
        ),
        _qtyBtn(
          icon: Icons.add,
          onTap: atLimit ? null : () => bloc?.add(AddItem(product: p)),
          disabled: atLimit,
        ),
        if (atLimit)
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Text('máx', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
          ),
      ],
    );
  }

  Widget _qtyBtn({required IconData icon, VoidCallback? onTap, bool disabled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 15, color: disabled ? const Color(0xFFBDBDBD) : _kPrimary),
      ),
    );
  }

  Widget _buildPriceAndDelete(Product p) {
    final lineTotal = p.effectivePrice * (p.quantity ?? 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₡${fmtPrice(lineTotal)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _kAccent,
          ),
        ),
        if (p.variantPrice != null && p.variantPrice! > 0) ...[
          const SizedBox(height: 2),
          Text(
            '₡${fmtPrice(p.effectivePrice)} c/u',
            style: const TextStyle(fontSize: 10, color: _kSub),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => bloc?.add(RemoveItem(product: p)),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          ),
        ),
      ],
    );
  }
}
