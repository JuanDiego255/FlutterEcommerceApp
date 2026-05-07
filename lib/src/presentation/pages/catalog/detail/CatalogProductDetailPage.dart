import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProductDetail.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/FullScreenImagePage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CatalogProductDetailPage extends StatelessWidget {
  const CatalogProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final product = args['product'] as CatalogProduct;
    return _DetailView(product: product);
  }
}

// ─── Main stateful view ───────────────────────────────────────────────────────

class _DetailView extends StatefulWidget {
  final CatalogProduct product;
  const _DetailView({required this.product});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _pageCtrl = PageController();
  final _service = CatalogService();

  CatalogProductDetail? _detail;
  bool _loadingDetail = true;
  String? _detailError;

  int _imageIndex = 0;
  CatalogVariant? _selectedVariant;
  bool _descExpanded = false;
  final _wishlist = WishlistNotifier.instance;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    final result = await _service.getProductDetail(widget.product.id);
    if (!mounted) return;

    CatalogProductDetail? detail;
    String? error;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        detail = CatalogProductDetail.fromJson(data);
      } else {
        error = 'Respuesta inválida del servidor';
      }
    } else if (result is Error<Map<String, dynamic>>) {
      error = result.message;
    }

    setState(() {
      _loadingDetail = false;
      _detail = detail;
      _detailError = error;
    });
  }

  Future<void> _toggleWishlist() async {
    if (_wishlist.contains(widget.product.id)) {
      await _wishlist.remove(widget.product.id);
      return;
    }
    String? variantLabel;
    double? variantPrice;

    if (_detail != null && _detail!.variants.isNotEmpty) {
      if (_selectedVariant != null) {
        variantLabel = _selectedVariant!.label;
        variantPrice = _selectedVariant!.hasCustomPrice ? _selectedVariant!.price : null;
      } else if (_detail!.variants.length == 1) {
        variantLabel = _detail!.variants.first.label;
        variantPrice = _detail!.variants.first.hasCustomPrice ? _detail!.variants.first.price : null;
      } else {
        final labels = _detail!.variants.map((v) => v.label).toList();
        final picked = await _showVariantSheet(labels);
        if (picked == null) return;
        variantLabel = picked;
        final match = _detail!.variants.firstWhere(
          (v) => v.label == picked,
          orElse: () => _detail!.variants.first,
        );
        variantPrice = match.hasCustomPrice ? match.price : null;
      }
    } else {
      final attrs = widget.product.availableAttrs;
      if (attrs.length == 1) {
        variantLabel = attrs.first;
      } else if (attrs.length > 1) {
        variantLabel = await _showVariantSheet(attrs);
        if (variantLabel == null) return;
      }
    }

    await _wishlist.add(WishlistItem(
      product: widget.product,
      variantLabel: variantLabel,
      variantPrice: variantPrice,
    ));
  }

  Future<String?> _showVariantSheet(List<String> labels) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => _VariantPickerSheet(labels: labels),
    );
  }

  double get _displayPrice {
    if (_selectedVariant != null && _selectedVariant!.hasCustomPrice) {
      return _selectedVariant!.price;
    }
    return _detail?.finalPrice ?? widget.product.finalPrice;
  }

  double get _basePrice => _detail?.price ?? widget.product.price;
  int get _discountPct => _detail?.discount ?? widget.product.discount;
  bool get _hasDiscount => _discountPct > 0 && _selectedVariant == null;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _wishlist,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallery(),
                _buildPriceBlock(),
                Divider(color: cs.outline, height: 1),
                if (_loadingDetail) _buildDetailLoading(),
                if (!_loadingDetail && _detail != null) ...[
                  if (_detail!.variants.isNotEmpty) _buildVariants(),
                  if ((_detail!.description ?? '').isNotEmpty) _buildDescription(),
                  _buildMeta(),
                ],
                if (!_loadingDetail && _detailError != null) _buildDetailError(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cs.onBackground),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.product.name,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onBackground),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              _wishlist.contains(widget.product.id) ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(_wishlist.contains(widget.product.id)),
              color: _wishlist.contains(widget.product.id) ? cs.error : tokens.textMuted,
              size: 22,
            ),
          ),
          onPressed: _toggleWishlist,
          tooltip: _wishlist.contains(widget.product.id) ? 'Quitar de favoritos' : 'Agregar a favoritos',
        ),
        IconButton(
          icon: Icon(Icons.share_outlined, color: cs.onBackground, size: 20),
          onPressed: _share,
          tooltip: 'Compartir',
        ),
      ],
    );
  }

  // ─── Image gallery ───────────────────────────────────────────────────────────

  Widget _buildGallery() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final urls = _detail?.imageUrls ?? [];

    if (urls.isEmpty) {
      final single = widget.product.imageUrl;
      if (single.isEmpty) {
        return AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            color: tokens.surfaceAlt,
            child: Center(
              child: Icon(Icons.image_outlined, size: 64, color: tokens.textSubtle),
            ),
          ),
        );
      }
      return Stack(
        children: [
          GestureDetector(
            onTap: () => FullScreenImagePage.show(context, [single]),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: CachedNetworkImage(
                imageUrl: single,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholder: (_, __) => Container(color: tokens.surfaceAlt),
                errorWidget: (_, __, ___) => _imagePlaceholder(),
              ),
            ),
          ),
          _buildExpandButton([single], 0),
        ],
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () => FullScreenImagePage.show(context, urls, index: _imageIndex),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Container(color: tokens.surfaceAlt),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  ),
                ),
              ),
            ),
            _buildExpandButton(urls, _imageIndex),
          ],
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              urls.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _imageIndex == i ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _imageIndex == i ? cs.primary : tokens.borderStrong,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildExpandButton(List<String> urls, int index) => Positioned(
        bottom: 10,
        right: 10,
        child: GestureDetector(
          onTap: () => FullScreenImagePage.show(context, urls, index: index),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
          ),
        ),
      );

  Widget _imagePlaceholder() {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      color: tokens.surfaceAlt,
      child: Center(
        child: Icon(Icons.image_outlined, size: 64, color: tokens.textSubtle),
      ),
    );
  }

  // ─── Price block ─────────────────────────────────────────────────────────────

  Widget _buildPriceBlock() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onBackground),
          ),
          if (widget.product.code?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              'Ref: ${widget.product.code}',
              style: TextStyle(fontSize: 12, color: tokens.textMuted),
            ),
          ],
          const SizedBox(height: 14),
          if (_hasDiscount) ...[
            Text(
              '₡${fmtPrice(_basePrice)}',
              style: TextStyle(
                fontSize: 14,
                color: tokens.textSubtle,
                decoration: TextDecoration.lineThrough,
                decorationColor: tokens.textSubtle,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₡${fmtPrice(_displayPrice)}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: cs.error),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$_discountPct%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Text(
              'Ahorrás ₡${fmtPrice(_basePrice - _displayPrice)}',
              style: TextStyle(fontSize: 12, color: tokens.success),
            ),
          ] else
            Text(
              '₡${fmtPrice(_displayPrice)}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: cs.primary),
            ),
        ],
      ),
    );
  }

  // ─── Variants ────────────────────────────────────────────────────────────────

  Widget _buildVariants() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final variants = _detail!.variants;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Variantes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onBackground),
              ),
              if (_selectedVariant != null) ...[
                const SizedBox(width: 8),
                Text(_selectedVariant!.label, style: TextStyle(fontSize: 13, color: cs.primary)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: variants.map((v) {
              final isSelected = _selectedVariant?.combinationId == v.combinationId;
              final outOfStock = !v.inStock;
              return GestureDetector(
                onTap: outOfStock
                    ? null
                    : () => setState(() => _selectedVariant = isSelected ? null : v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : cs.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: outOfStock
                          ? tokens.borderStrong
                          : isSelected
                              ? cs.primary
                              : cs.outline,
                    ),
                  ),
                  child: Text(
                    outOfStock ? '${v.label} (agotado)' : v.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: outOfStock
                          ? tokens.textSubtle
                          : isSelected
                              ? cs.onPrimary
                              : cs.onBackground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Divider(color: cs.outline, height: 1),
        ],
      ),
    );
  }

  // ─── Description ─────────────────────────────────────────────────────────────

  Widget _buildDescription() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final desc = _detail!.description!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final isLong = desc.length > 200;
    final displayText = isLong && !_descExpanded ? '${desc.substring(0, 200)}...' : desc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onBackground),
          ),
          const SizedBox(height: 8),
          Text(displayText, style: TextStyle(fontSize: 13, color: tokens.textMuted, height: 1.6)),
          if (isLong) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(
                _descExpanded ? 'Ver menos' : 'Ver más',
                style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: cs.outline, height: 1),
        ],
      ),
    );
  }

  // ─── Metadata (stock, categories) ────────────────────────────────────────────

  Widget _buildMeta() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final d = _detail!;
    final totalStock = d.stock;
    final showStock = d.manageStock == 1;
    final hasCategories = d.categories.isNotEmpty;

    if (!showStock && !hasCategories) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStock)
            Row(
              children: [
                Icon(
                  totalStock > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 16,
                  color: totalStock > 0 ? tokens.success : cs.error,
                ),
                const SizedBox(width: 6),
                Text(
                  totalStock > 0 ? 'En stock ($totalStock disponibles)' : 'Sin stock',
                  style: TextStyle(fontSize: 13, color: totalStock > 0 ? tokens.success : cs.error),
                ),
              ],
            ),
          if (showStock && hasCategories) const SizedBox(height: 10),
          if (hasCategories)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: d.categories
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ─── Detail loading / error ───────────────────────────────────────────────────

  Widget _buildDetailLoading() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2)),
    );
  }

  Widget _buildDetailError() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: tokens.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_detailError!, style: TextStyle(fontSize: 12, color: tokens.textMuted)),
          ),
          TextButton(
            onPressed: _loadDetail,
            child: Text('Reintentar', style: TextStyle(color: cs.primary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: cs.background,
          border: Border(top: BorderSide(color: cs.outline)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.35)),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20),
                onPressed: _shareWhatsApp,
                tooltip: 'Consultar por WhatsApp',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                onPressed: _addToCart,
                label: const Text('Agregar al carrito', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _addToCart() async {
    if (_detail != null && _detail!.variants.isNotEmpty && _selectedVariant == null) {
      if (_detail!.variants.length == 1) {
        setState(() => _selectedVariant = _detail!.variants.first);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Por favor seleccioná una variante primero'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
        return;
      }
    }

    final variantLabel = _selectedVariant?.label;
    final double? vPrice = (_selectedVariant != null && _selectedVariant!.hasCustomPrice)
        ? _selectedVariant!.price
        : null;

    final product = Product(
      id: widget.product.id,
      name: widget.product.name,
      description: _detail?.description ?? widget.product.name,
      image1: widget.product.imageUrl.isNotEmpty ? widget.product.imageUrl : null,
      image2: null,
      idCategory: 0,
      price: widget.product.finalPrice,
      quantity: 1,
      selectedVariant: variantLabel,
      variantPrice: vPrice,
      variantCombinationId: (_selectedVariant != null && _selectedVariant!.combinationId > 0)
          ? _selectedVariant!.combinationId
          : null,
      variantStock: _selectedVariant?.stock,
      variantManageStock: _selectedVariant?.manageStock,
    );

    await locator<ShoppingBagUseCases>().add.run(product);

    final allProducts = await locator<ShoppingBagUseCases>().getProducts.run();
    CartNotifier.instance.update(allProducts.length);

    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(variantLabel != null
            ? '${widget.product.name} ($variantLabel) agregado al carrito'
            : '${widget.product.name} agregado al carrito'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.surface,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Ver carrito',
          textColor: cs.primary,
          onPressed: () => Navigator.pushNamed(context, 'client/shopping_bag'),
        ),
      ),
    );
  }

  void _share() async {
    final price = _displayPrice;
    final text = Uri.encodeComponent(
      '${widget.product.name}\n'
      'Precio: ₡${fmtPrice(price)}\n'
      '${widget.product.imageUrl}',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareWhatsApp() async {
    final price = _displayPrice;
    final variantNote = _selectedVariant != null ? '\nVariante: ${_selectedVariant!.label}' : '';
    final text = Uri.encodeComponent(
      'Hola! Me interesa este producto:\n'
      '*${widget.product.name}*$variantNote\n'
      'Precio: ₡${fmtPrice(price)}\n'
      '${widget.product.imageUrl}',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Variant picker sheet ─────────────────────────────────────────────────────

class _VariantPickerSheet extends StatelessWidget {
  final List<String> labels;
  const _VariantPickerSheet({required this.labels});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleccioná una variante',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onBackground),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: labels
                    .map((l) => GestureDetector(
                          onTap: () => Navigator.pop(context, l),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: cs.primary.withOpacity(0.3)),
                            ),
                            child: Text(
                              l,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
