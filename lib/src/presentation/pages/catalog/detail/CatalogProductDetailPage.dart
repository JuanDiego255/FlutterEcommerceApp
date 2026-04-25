import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProductDetail.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _kPrimary  = Color(0xFF2D2D2D);
const _kAccent   = Color(0xFF8B6F47);
const _kBg       = Color(0xFFFAFAFA);
const _kSub      = Color(0xFF757575);
const _kDivider  = Color(0xFFEEEEEE);
const _kRed      = Color(0xFFE53935);
const _kGreen    = Color(0xFF43A047);

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
  bool _inWishlist = false;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkWishlist();
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

  Future<void> _checkWishlist() async {
    final has = await WishlistService.contains(widget.product.id);
    if (mounted) setState(() => _inWishlist = has);
  }

  Future<void> _toggleWishlist() async {
    if (_inWishlist) {
      await WishlistService.remove(widget.product.id);
      if (mounted) setState(() => _inWishlist = false);
      return;
    }
    // If detail is loaded, pick from full variants; otherwise fall back to availableAttrs
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
        final match = _detail!.variants.firstWhere((v) => v.label == picked, orElse: () => _detail!.variants.first);
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

    await WishlistService.add(WishlistItem(
      product: widget.product,
      variantLabel: variantLabel,
      variantPrice: variantPrice,
    ));
    if (mounted) setState(() => _inWishlist = true);
  }

  Future<String?> _showVariantSheet(List<String> labels) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallery(),
                _buildPriceBlock(),
                const Divider(color: _kDivider, height: 1),
                if (_loadingDetail) _buildDetailLoading(),
                if (!_loadingDetail && _detail != null) ...[
                  if ((_detail!.variants).isNotEmpty) _buildVariants(),
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

  SliverAppBar _buildAppBar() => SliverAppBar(
        pinned: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _kDivider,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                _inWishlist ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(_inWishlist),
                color: _inWishlist ? _kRed : _kSub,
                size: 22,
              ),
            ),
            onPressed: _toggleWishlist,
            tooltip: _inWishlist ? 'Quitar de favoritos' : 'Agregar a favoritos',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: _kPrimary, size: 20),
            onPressed: _share,
            tooltip: 'Compartir',
          ),
        ],
      );

  // ─── Image gallery ───────────────────────────────────────────────────────────

  Widget _buildGallery() {
    final urls = _detail?.imageUrls ?? [];
    if (urls.isEmpty) {
      final single = widget.product.imageUrl;
      if (single.isEmpty) {
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: const Center(
              child: Icon(Icons.image_outlined, size: 64, color: Color(0xFFBDBDBD)),
            ),
          ),
        );
      }
      return AspectRatio(
        aspectRatio: 1,
        child: CachedNetworkImage(
          imageUrl: single,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
          errorWidget: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: urls[i],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
              errorWidget: (_, __, ___) => _imagePlaceholder(),
            ),
          ),
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
                  color: _imageIndex == i ? _kAccent : const Color(0xFFD0D0D0),
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

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 64, color: Color(0xFFBDBDBD)),
        ),
      );

  // ─── Price block ─────────────────────────────────────────────────────────────

  Widget _buildPriceBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          if (widget.product.code?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              'Ref: ${widget.product.code}',
              style: const TextStyle(fontSize: 12, color: _kSub),
            ),
          ],
          const SizedBox(height: 14),
          if (_hasDiscount) ...[
            Text(
              '₡${fmtPrice(_basePrice)}',
              style: const TextStyle(
                fontSize: 14,
                color: _kSub,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₡${fmtPrice(_displayPrice)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _kRed,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$_discountPct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Ahorrás ₡${fmtPrice(_basePrice - _displayPrice)}',
              style: const TextStyle(fontSize: 12, color: _kGreen),
            ),
          ] else
            Text(
              '₡${fmtPrice(_displayPrice)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kAccent,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Variants ────────────────────────────────────────────────────────────────

  Widget _buildVariants() {
    final variants = _detail!.variants;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Variantes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              if (_selectedVariant != null) ...[
                const SizedBox(width: 8),
                Text(
                  _selectedVariant!.label,
                  style: const TextStyle(fontSize: 13, color: _kAccent),
                ),
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
                    : () => setState(
                          () => _selectedVariant =
                              isSelected ? null : v,
                        ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _kAccent : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: outOfStock
                          ? const Color(0xFFD0D0D0)
                          : isSelected
                              ? _kAccent
                              : _kDivider,
                    ),
                  ),
                  child: Text(
                    outOfStock ? '${v.label} (agotado)' : v.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: outOfStock
                          ? const Color(0xFFBBBBBB)
                          : isSelected
                              ? Colors.white
                              : _kPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: _kDivider, height: 1),
        ],
      ),
    );
  }

  // ─── Description ─────────────────────────────────────────────────────────────

  Widget _buildDescription() {
    final desc = _detail!.description!;
    final isLong = desc.length > 200;
    final displayText =
        isLong && !_descExpanded ? '${desc.substring(0, 200)}...' : desc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: const TextStyle(fontSize: 13, color: _kSub, height: 1.6),
          ),
          if (isLong) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(
                _descExpanded ? 'Ver menos' : 'Ver más',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: _kDivider, height: 1),
        ],
      ),
    );
  }

  // ─── Metadata (stock, categories) ────────────────────────────────────────────

  Widget _buildMeta() {
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
                  totalStock > 0
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 16,
                  color: totalStock > 0 ? _kGreen : _kRed,
                ),
                const SizedBox(width: 6),
                Text(
                  totalStock > 0
                      ? 'En stock ($totalStock disponibles)'
                      : 'Sin stock',
                  style: TextStyle(
                    fontSize: 13,
                    color: totalStock > 0 ? _kGreen : _kRed,
                  ),
                ),
              ],
            ),
          if (showStock && hasCategories) const SizedBox(height: 10),
          if (hasCategories) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: d.categories
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0EB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Detail loading / error ───────────────────────────────────────────────────

  Widget _buildDetailLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2)),
      );

  Widget _buildDetailError() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, size: 16, color: _kSub),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _detailError!,
                style: const TextStyle(fontSize: 12, color: _kSub),
              ),
            ),
            TextButton(
              onPressed: _loadDetail,
              child: const Text('Reintentar', style: TextStyle(color: _kAccent, fontSize: 12)),
            ),
          ],
        ),
      );

  // ─── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar() => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _kDivider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  onPressed: _shareWhatsApp,
                  label: const Text(
                    'Consultar por WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ─── Actions ─────────────────────────────────────────────────────────────────

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
    final variantNote =
        _selectedVariant != null ? '\nVariante: ${_selectedVariant!.label}' : '';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Seleccioná una variante',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: labels.map((l) => GestureDetector(
                  onTap: () => Navigator.pop(context, l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF8B6F47).withOpacity(0.3)),
                    ),
                    child: Text(l,
                        style: const TextStyle(
                          fontSize: 13, color: Color(0xFF8B6F47), fontWeight: FontWeight.w600,
                        )),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
