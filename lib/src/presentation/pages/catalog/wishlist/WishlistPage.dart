import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _kPrimary  = Color(0xFF2D2D2D);
const _kAccent   = Color(0xFF8B6F47);
const _kBg       = Color(0xFFFAFAFA);
const _kCard     = Colors.white;
const _kSub      = Color(0xFF757575);
const _kDivider  = Color(0xFFEEEEEE);
const _kRed      = Color(0xFFE53935);

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<CatalogProduct> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await WishlistService.getAll();
    if (mounted) setState(() { _products = list; _loading = false; });
  }

  Future<void> _remove(int id) async {
    await WishlistService.remove(id);
    setState(() => _products.removeWhere((p) => p.id == id));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar favoritos'),
        content: const Text('¿Querés eliminar todos los productos guardados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await WishlistService.clear();
      if (mounted) setState(() => _products.clear());
    }
  }

  void _shareAll() async {
    if (_products.isEmpty) return;
    final lines = _products.map((p) {
      final price = p.hasDiscount ? p.finalPrice : p.price;
      return '• ${p.name} — ₡${_fmt(price)}';
    }).join('\n');
    final text = Uri.encodeComponent('Mi lista de favoritos:\n$lines');
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _kDivider,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _loading
              ? 'Favoritos'
              : _products.isEmpty
                  ? 'Favoritos'
                  : 'Favoritos (${_products.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        actions: [
          if (_products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: _kSub, size: 22),
              onPressed: _clearAll,
              tooltip: 'Vaciar lista',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : _products.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      bottomNavigationBar: _products.isNotEmpty ? _buildShareBar() : null,
    );
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 20),
              const Text(
                'Tu lista de favoritos está vacía',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Guardá productos desde su página de detalle tocando el corazón.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAccent,
                  side: const BorderSide(color: _kAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Explorar catálogo'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

  Widget _buildList() => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _WishlistCard(
          product: _products[i],
          onRemove: () => _remove(_products[i].id),
          onTap: () => Navigator.pushNamed(
            context,
            'catalog/product/detail',
            arguments: {'product': _products[i]},
          ).then((_) => _load()),
        ),
      );

  Widget _buildShareBar() => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: _kCard,
            border: Border(top: BorderSide(color: _kDivider)),
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.share_outlined, size: 18),
            onPressed: _shareAll,
            label: const Text(
              'Compartir lista por WhatsApp',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
}

// ─── Wishlist card ────────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _WishlistCard({
    required this.product,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: const Color(0xFFF5F5F5)),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildPrice(),
                    if (product.availableAttrs.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.availableAttrs.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _kSub),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.favorite, color: _kRed, size: 22),
              onPressed: onRemove,
              tooltip: 'Quitar de favoritos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrice() {
    if (product.hasDiscount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₡${_fmt(product.price)}',
            style: const TextStyle(
              fontSize: 10,
              color: _kSub,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '₡${_fmt(product.finalPrice)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kRed,
            ),
          ),
        ],
      );
    }
    return Text(
      '₡${_fmt(product.price)}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _kAccent,
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 28, color: Color(0xFFBDBDBD)),
        ),
      );

  String _fmt(double v) {
    if (v == v.truncate()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
