import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/MitaiProduct.dart';
import 'package:ecommerce_flutter/src/domain/models/ProductVariant.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminProductFormPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

const Color _kBg = Color(0xFFFAF8F5);
const Color _kPrimary = Color(0xFF8B6F47);
const Color _kAccent = Color(0xFFC8966A);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kTextPrimary = Color(0xFF1A1A1A);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kStockOk = Color(0xFF22C55E);
const Color _kStockLow = Color(0xFFF59E0B);
const Color _kStockOut = Color(0xFFEF4444);

class AdminProductDetailPage extends StatefulWidget {
  final MitaiProduct product;
  final int categoryId;

  const AdminProductDetailPage({
    super.key,
    required this.product,
    required this.categoryId,
  });

  @override
  State<AdminProductDetailPage> createState() => _AdminProductDetailPageState();
}

class _AdminProductDetailPageState extends State<AdminProductDetailPage> {
  final _api = MitaiApiService();
  final _fmt = NumberFormat('#,###', 'es');
  final _screenshotController = ScreenshotController();

  bool _loadingVariants = true;
  bool _sharing = false;
  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    if (widget.product.id != null) _loadVariants();
  }

  Future<void> _loadVariants() async {
    final res = await _api.getProductVariants(widget.product.id!);
    if (!mounted) return;
    if (res is Success<List<ProductVariant>>) {
      setState(() {
        _variants = res.data;
        _loadingVariants = false;
      });
    } else {
      setState(() {
        _loadingVariants = false;
      });
    }
  }

  Future<void> _shareProductCard() async {
    setState(() => _sharing = true);
    try {
      final imageBytes = await _screenshotController.captureFromLongWidget(
        InheritedTheme.captureAll(
          context,
          Material(
            color: Colors.transparent,
            child: _ProductShareCard(
              product: widget.product,
              variants: _variants,
              fmt: _fmt,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 400),
        pixelRatio: 3.0,
      );
      final text =
          '${widget.product.name}\n₡${_fmt.format(widget.product.price)}';
      await Share.shareXFiles(
        [
          XFile.fromData(
            imageBytes,
            name: 'producto.png',
            mimeType: 'image/png',
          ),
        ],
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar tarjeta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _openEditForm() async {
    if (widget.product.id == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductFormPage(
          categoryId: widget.categoryId,
          product: widget.product,
        ),
      ),
    );
    if (updated == true && mounted) {
      _loadVariants();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(p),
          SliverToBoxAdapter(child: _buildBody(p)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'edit',
            onPressed: _openEditForm,
            backgroundColor: Colors.white,
            elevation: 2,
            mini: true,
            tooltip: 'Editar producto',
            child: const Icon(Icons.edit_outlined, color: _kPrimary, size: 20),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'share',
            onPressed: _sharing ? null : _shareProductCard,
            backgroundColor: _kPrimary,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined, color: Colors.white),
            label: Text(
              _sharing ? 'Generando...' : 'Compartir',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(MitaiProduct p) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: _kSurface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios, size: 16, color: _kPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: p.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: p.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _imagePlaceholder(),
                errorWidget: (_, __, ___) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF0EBE3),
      child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 64, color: _kAccent)),
    );
  }

  Widget _buildBody(MitaiProduct p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(p),
          const SizedBox(height: 20),
          _buildInfoCard(p),
          if (p.description != null && p.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDescriptionCard(p),
          ],
          const SizedBox(height: 16),
          _buildVariantsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(MitaiProduct p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                p.name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    height: 1.2),
              ),
            ),
            const SizedBox(width: 12),
            _stockChip(p),
          ],
        ),
        if (p.code != null && p.code!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Código: ${p.code}',
              style: const TextStyle(
                  fontSize: 12,
                  color: _kTextSecondary,
                  fontFamily: 'monospace')),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₡${_fmt.format(p.price)}',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            if (p.mayorPrice != null && p.mayorPrice! > 0) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('Mayoreo: ₡${_fmt.format(p.mayorPrice)}',
                    style: const TextStyle(
                        fontSize: 13, color: _kTextSecondary)),
              ),
            ],
          ],
        ),
        if (p.discount != null && p.discount! > 0) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${p.discount}% descuento',
                style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }

  Widget _stockChip(MitaiProduct p) {
    if (p.manageStock == 0) {
      return _chip('Sin control', const Color(0xFF6B6B6B),
          const Color(0xFFF0F0F0));
    }
    final s = p.totalStock ?? 0;
    if (s <= 0) return _chip('Agotado', _kStockOut, _kStockOut.withOpacity(0.12));
    if (s <= 5) return _chip('Bajo: $s', _kStockLow, _kStockLow.withOpacity(0.12));
    return _chip('Stock: $s', _kStockOk, _kStockOk.withOpacity(0.12));
  }

  Widget _chip(String label, Color text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: text, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoCard(MitaiProduct p) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _infoRow('Control de stock',
              p.manageStock == 1 ? 'Activo' : 'Sin control',
              isFirst: true),
          if (p.manageStock == 1)
            _infoRow('Stock total', '${p.totalStock ?? 0} unidades'),
          if (p.attrList.isNotEmpty)
            _infoRow('Atributos', p.attrList.map((a) => a.trim()).join(', ')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {bool isFirst = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFF0EBE3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: _kTextSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary)),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(MitaiProduct p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Descripción',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 8),
          Text(p.description!,
              style: const TextStyle(
                  fontSize: 13, color: _kTextSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Variantes',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary)),
            if (!_loadingVariants) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_variants.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingVariants)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: _kPrimary, strokeWidth: 2)))
        else if (_variants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Text('Sin variantes registradas',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextSecondary, fontSize: 13)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5EDE0),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 4,
                          child: Text('Combinación',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Stock',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextSecondary))),
                      Expanded(
                          flex: 2,
                          child: Text('Precio',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextSecondary))),
                    ],
                  ),
                ),
                ...List.generate(_variants.length, (i) {
                  final v = _variants[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Color(0xFFF0EBE3), width: 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 4,
                            child: Text(v.label,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: _kTextPrimary,
                                    fontWeight: FontWeight.w500))),
                        Expanded(
                            flex: 2,
                            child: Center(
                                child: _variantStockBadge(v))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            v.price > 0
                                ? '₡${_fmt.format(v.price)}'
                                : 'Base',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: v.price > 0
                                  ? _kPrimary
                                  : _kTextSecondary,
                              fontWeight: v.price > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _variantStockBadge(ProductVariant v) {
    if (v.manageStock == 0) {
      return const Text('—',
          style: TextStyle(color: _kTextSecondary, fontSize: 12));
    }
    Color color;
    if (v.stock <= 0) {
      color = _kStockOut;
    } else if (v.stock <= 5) {
      color = _kStockLow;
    } else {
      color = _kStockOk;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('${v.stock}',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de producto para compartir
// ─────────────────────────────────────────────────────────────────────────────

class _ProductShareCard extends StatelessWidget {
  final MitaiProduct product;
  final List<ProductVariant> variants;
  final NumberFormat fmt;

  const _ProductShareCard({
    required this.product,
    required this.variants,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      color: const Color(0xFFFAF8F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildImage(),
          _buildInfo(),
          if (variants.isNotEmpty) _buildVariants(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B4F30), Color(0xFF8B6F47)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Text(
            'Mitaï',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (product.imageUrl.isEmpty) {
      return Container(
        height: 260,
        color: const Color(0xFFF0EBE3),
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 80, color: Color(0xFFC8966A)),
        ),
      );
    }
    return SizedBox(
      height: 260,
      child: CachedNetworkImage(
        imageUrl: product.imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 260,
          color: const Color(0xFFF0EBE3),
          child: const Center(
            child: Icon(Icons.inventory_2_outlined,
                size: 80, color: Color(0xFFC8966A)),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 260,
          color: const Color(0xFFF0EBE3),
          child: const Center(
            child: Icon(Icons.inventory_2_outlined,
                size: 80, color: Color(0xFFC8966A)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    final stockColor = _stockColor();
    final stockText = _stockText();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stockText,
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (product.code != null && product.code!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Cód: ${product.code}',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B6B6B), fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '₡ ${fmt.format(product.price)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8B6F47),
            ),
          ),
          if (product.mayorPrice != null && product.mayorPrice! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Precio mayoreo: ₡ ${fmt.format(product.mayorPrice)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)),
            ),
          ],
          if (product.discount != null && product.discount! > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${product.discount}% de descuento',
                style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariants() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0EBE3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFF5EDE0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('Variante',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B6B6B)))),
                Expanded(
                    flex: 2,
                    child: Text('Stock',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B6B6B)))),
                Expanded(
                    flex: 2,
                    child: Text('Precio',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B6B6B)))),
              ],
            ),
          ),
          ...variants.map((v) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFFF0EBE3), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 4,
                        child: Text(v.label,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF1A1A1A)))),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          '${v.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: v.stock <= 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        v.price > 0 ? '₡ ${fmt.format(v.price)}' : 'Base',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: v.price > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: v.price > 0
                              ? const Color(0xFF8B6F47)
                              : const Color(0xFF6B6B6B),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: const Color(0xFFFAF8F5),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFFC8966A)),
            const SizedBox(width: 6),
            Text(
              TenantSession.host,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8B6F47),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _stockColor() {
    if (product.manageStock == 0) return const Color(0xFF6B6B6B);
    final s = product.totalStock ?? 0;
    if (s <= 0) return const Color(0xFFEF4444);
    if (s <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  String _stockText() {
    if (product.manageStock == 0) return 'Disponible';
    final s = product.totalStock ?? 0;
    if (s <= 0) return 'Agotado';
    if (s <= 5) return 'Últimas unidades';
    return 'En stock';
  }
}
