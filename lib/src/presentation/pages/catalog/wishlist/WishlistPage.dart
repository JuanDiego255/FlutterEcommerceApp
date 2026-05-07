import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WishlistPage extends StatefulWidget {
  final bool embedded;
  const WishlistPage({super.key, this.embedded = false});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<WishlistItem> _items = [];
  bool _loading = true;
  final _service = CatalogService();

  @override
  void initState() {
    super.initState();
    _load();
    WishlistNotifier.instance.addListener(_onWishlistChanged);
  }

  @override
  void dispose() {
    WishlistNotifier.instance.removeListener(_onWishlistChanged);
    super.dispose();
  }

  void _onWishlistChanged() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await WishlistService.getAll();
    if (mounted) setState(() { _items = list; _loading = false; });
  }

  Future<void> _remove(int id) async {
    await WishlistNotifier.instance.remove(id);
    setState(() => _items.removeWhere((i) => i.product.id == id));
  }

  Future<void> _clearAll() async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Vaciar favoritos', style: TextStyle(color: cs.onBackground)),
        content: Text('¿Querés eliminar todos los productos guardados?', style: TextStyle(color: cs.onBackground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await WishlistNotifier.instance.clear();
      if (mounted) setState(() => _items.clear());
    }
  }

  Future<void> _changeVariant(WishlistItem item) async {
    final pick = await showModalBottomSheet<_VariantPick>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VariantPickerSheet(service: _service, productId: item.product.id),
    );
    if (pick == null || !mounted) return;
    await WishlistService.updateVariant(item.product.id, pick.label, pick.price);
    _load();
  }

  void _shareAll() async {
    if (_items.isEmpty) return;
    final lines = _items.map((item) {
      final variant = item.variantLabel != null ? ' (${item.variantLabel})' : '';
      return '• ${item.product.name}$variant — ₡${fmtPrice(item.displayPrice)}';
    }).join('\n');
    final text = Uri.encodeComponent('Mi lista de favoritos:\n$lines');
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cs.onBackground),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _loading
              ? 'Favoritos'
              : _items.isEmpty ? 'Favoritos' : 'Favoritos (${_items.length})',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onBackground),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: tokens.textMuted, size: 22),
              onPressed: _clearAll,
              tooltip: 'Vaciar lista',
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _items.isEmpty ? _buildEmptyState() : _buildList(),
      bottomNavigationBar: _items.isNotEmpty ? _buildShareBar() : null,
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: tokens.textSubtle),
            const SizedBox(height: 20),
            Text(
              'Tu lista de favoritos está vacía',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onBackground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Guardá productos desde su página de detalle tocando el corazón.',
              style: TextStyle(fontSize: 13, color: tokens.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Explorar catálogo'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _WishlistCard(
          item: _items[i],
          onRemove: () => _remove(_items[i].product.id),
          onTap: () => Navigator.pushNamed(
            context,
            'catalog/product/detail',
            arguments: {'product': _items[i].product},
          ).then((_) => _load()),
          onChangeVariant: _items[i].variantLabel != null ? () => _changeVariant(_items[i]) : null,
        ),
      );

  Widget _buildShareBar() {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: cs.background,
          border: Border(top: BorderSide(color: cs.outline)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(Icons.share_outlined, size: 18),
          onPressed: _shareAll,
          label: const Text('Compartir lista por WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ─── Wishlist card ────────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final VoidCallback? onChangeVariant;

  const _WishlistCard({
    required this.item,
    required this.onRemove,
    required this.onTap,
    this.onChangeVariant,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final p = item.product;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
              child: SizedBox(
                width: 90, height: 90,
                child: p.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: tokens.surfaceAlt),
                        errorWidget: (_, __, ___) => _placeholder(tokens),
                      )
                    : _placeholder(tokens),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onBackground)),
                    const SizedBox(height: 4),
                    if (item.variantPrice != null && item.variantPrice! > 0)
                      Text('₡${fmtPrice(item.displayPrice)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary))
                    else if (p.hasDiscount) ...[
                      Text('₡${fmtPrice(p.price)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: tokens.textSubtle,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: tokens.textSubtle,
                          )),
                      Text('₡${fmtPrice(p.finalPrice)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.error)),
                    ] else
                      Text('₡${fmtPrice(item.displayPrice)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary)),
                    if (item.variantLabel != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(color: cs.primary.withOpacity(0.3)),
                              ),
                              child: Text(item.variantLabel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500)),
                            ),
                          ),
                          if (onChangeVariant != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: onChangeVariant,
                              child: Text(
                                'Cambiar',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: cs.error, size: 22),
              onPressed: onRemove,
              tooltip: 'Quitar de favoritos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppTokens tokens) => Container(
        color: tokens.surfaceAlt,
        child: Center(child: Icon(Icons.image_outlined, size: 28, color: tokens.textSubtle)),
      );
}

// ─── Variant picker data ───────────────────────────────────────────────────────

class _VariantPick {
  final String label;
  final double? price;
  const _VariantPick(this.label, this.price);
}

// ─── Variant picker sheet ─────────────────────────────────────────────────────

class _VariantPickerSheet extends StatefulWidget {
  final CatalogService service;
  final int productId;
  const _VariantPickerSheet({required this.service, required this.productId});
  @override
  State<_VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<_VariantPickerSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _variants = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final result = await widget.service.getProductVariants(widget.productId);
    if (!mounted) return;
    if (result is Success<List<dynamic>>) {
      final inStock = result.data
          .whereType<Map<String, dynamic>>()
          .where((v) {
            final manageStock = (v['manage_stock'] as num?)?.toInt() ?? 1;
            final stock = (v['stock'] as num?)?.toInt() ?? 0;
            return manageStock == 0 || stock > 0;
          })
          .toList();
      setState(() { _variants = inStock; _loading = false; });
    } else {
      setState(() { _error = 'No se pudieron cargar las variantes'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Cambiar variante',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onBackground)),
          const SizedBox(height: 14),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: cs.primary),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(_error!, style: TextStyle(color: tokens.textMuted)),
              ),
            )
          else if (_variants.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('No hay variantes disponibles', style: TextStyle(color: tokens.textMuted)),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _variants.map((v) {
                    final label = v['label']?.toString() ?? '';
                    final price = (v['price'] as num?)?.toDouble();
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, _VariantPick(label, price)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: cs.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600)),
                            if (price != null && price > 0)
                              Text('₡${fmtPrice(price)}', style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
