import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/MitaiProduct.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminProductDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminProductFormPage.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCatalogProductsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const AdminCatalogProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<AdminCatalogProductsPage> createState() => _AdminCatalogProductsPageState();
}

class _AdminCatalogProductsPageState extends State<AdminCatalogProductsPage> {
  final _api           = MitaiApiService();
  final _currencyFmt   = NumberFormat('#,###', 'es');
  final _searchCtrl    = TextEditingController();

  List<MitaiProduct> _products = [];

  String _search      = '';
  String? _attrFilter;

  bool _loading    = true;
  bool _loadingMore = false;
  String? _error;
  int  _currentPage = 1;
  int  _lastPage    = 1;
  int  _total       = 0;
  static const _perPage = 15;

  List<String> _availableAttrs = [];

  @override
  void initState() {
    super.initState();
    _loadData(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading    = true;
        _error      = null;
        _currentPage = 1;
        _products   = [];
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final result = await _api.getProductsByCategoryPaged(
      widget.categoryId,
      page:    _currentPage,
      perPage: _perPage,
      status:  '1',
      search:  _search,
    );

    if (!mounted) return;

    if (result is Success<Map<String, dynamic>>) {
      final data  = result.data;
      final list  = MitaiProduct.fromJsonList(data['data'] as List<dynamic>? ?? []);
      final pag   = data['pagination'] as Map<String, dynamic>? ?? {};

      final attrSet = <String>{};
      for (final p in list) {
        attrSet.addAll(p.attrList.where((a) => a.isNotEmpty));
      }
      if (reset) attrSet.addAll(_availableAttrs);
      if (reset) {
        _availableAttrs = attrSet.toList()..sort();
      } else {
        _availableAttrs = ({..._availableAttrs, ...attrSet}).toList()..sort();
      }

      setState(() {
        if (reset) {
          _products = list;
        } else {
          _products.addAll(list);
        }
        _lastPage    = pag['last_page'] as int? ?? 1;
        _total       = pag['total'] as int? ?? list.length;
        _loading     = false;
        _loadingMore = false;
      });
    } else if (result is Error<Map<String, dynamic>>) {
      setState(() {
        _error       = result.message;
        _loading     = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearch(String val) {
    _search = val;
    _attrFilter = null;
    _loadData(reset: true);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _search = '';
    _loadData(reset: true);
  }

  void _loadMore() {
    if (_loadingMore || _currentPage >= _lastPage) return;
    _currentPage++;
    _loadData();
  }

  List<MitaiProduct> get _filtered {
    if (_attrFilter == null) return _products;
    return _products
        .where((p) => p.attrList.any((a) => a.trim() == _attrFilter))
        .toList();
  }

  Future<void> _openForm({MitaiProduct? product}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductFormPage(
          product: product,
          categoryId: widget.categoryId,
        ),
      ),
    );
    if (changed == true) _loadData(reset: true);
  }

  Future<void> _confirmDelete(MitaiProduct product) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Eliminar producto',
            style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700)),
        content: Text('¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
            style: TextStyle(color: Theme.of(context).extension<AppTokens>()!.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: cs.error, foregroundColor: cs.onError),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || product.id == null) return;

    final result = await _api.deleteProduct(product.id!);
    if (!mounted) return;
    if (result is Success<bool>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} eliminado'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData(reset: true);
    } else if (result is Error<bool>) {
      final cs2 = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${(result).message}'),
          backgroundColor: cs2.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.categoryName,
            style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser, color: cs.primary),
            tooltip: 'Gestionar en web',
            onPressed: () => launchUrl(
              Uri.https(TenantSession.host, '/categories/${widget.categoryId}'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchBar(cs),
          if (_availableAttrs.isNotEmpty) _buildAttrFilter(cs),
          Expanded(child: _buildBody(cs)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          if (v.length >= 2 || v.isEmpty) _onSearch(v);
        },
        onSubmitted: _onSearch,
        style: TextStyle(fontSize: 14, color: cs.onBackground),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o código...',
          hintStyle: TextStyle(color: tokens.textMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: cs.primary, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: tokens.textMuted, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: cs.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildAttrFilter(ColorScheme cs) {
    return Container(
      color: cs.surface,
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableAttrs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == 0) {
            return FilterChip(
              label: const Text('Todos', style: TextStyle(fontSize: 11)),
              selected: _attrFilter == null,
              onSelected: (_) => setState(() => _attrFilter = null),
              selectedColor: cs.primary,
              labelStyle: TextStyle(color: _attrFilter == null ? cs.onPrimary : cs.onBackground),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }
          final attr = _availableAttrs[i - 1];
          final sel  = _attrFilter == attr;
          return FilterChip(
            label: Text(attr, style: TextStyle(fontSize: 11, color: sel ? cs.onPrimary : cs.onBackground)),
            selected: sel,
            onSelected: (_) => setState(() => _attrFilter = sel ? null : attr),
            selectedColor: cs.primary,
            backgroundColor: Theme.of(context).extension<AppTokens>()!.surfaceAlt,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(reset: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final visible = _filtered;
    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 56, color: tokens.textSubtle),
            const SizedBox(height: 12),
            Text(
              _search.isNotEmpty ? 'Sin resultados para "$_search"' : 'No hay productos en esta categoría',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text('$_total producto${_total == 1 ? '' : 's'}',
                  style: TextStyle(color: tokens.textMuted, fontSize: 12)),
              const Spacer(),
              if (_search.isNotEmpty)
                Text('Mostrando ${visible.length} resultado${visible.length == 1 ? '' : 's'}',
                    style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadData(reset: true),
            color: cs.primary,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: visible.length + (_currentPage < _lastPage ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == visible.length) {
                  if (!_loadingMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                  }
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2)));
                }
                final product = visible[index];
                return _ProductCard(
                  product: product,
                  currencyFormat: _currencyFmt,
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminProductDetailPage(
                          product: product,
                          categoryId: widget.categoryId,
                        ),
                      ),
                    );
                    if (changed == true) _loadData(reset: true);
                  },
                  onEdit: () => _openForm(product: product),
                  onDelete: () => _confirmDelete(product),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final MitaiProduct product;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.currencyFormat,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _stockColor(int? stock, ColorScheme cs, AppTokens tokens) {
    if (stock == null || stock == 0) return cs.error;
    if (stock <= 5) return tokens.warning;
    return tokens.success;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 130,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 130,
                            placeholder: (_, __) => Container(color: tokens.surfaceAlt,
                                child: Center(child: CircularProgressIndicator(
                                    color: cs.primary, strokeWidth: 2))),
                            errorWidget: (_, __, ___) => _placeholder(tokens),
                          )
                        : _placeholder(tokens),
                    Positioned(
                      top: 4, left: 4,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_outline, size: 14, color: cs.error),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit, size: 14, color: cs.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: TextStyle(color: cs.onBackground,
                            fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('₡${currencyFormat.format(product.price)}',
                        style: TextStyle(color: cs.primary,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const Spacer(),
                    if (product.manageStock == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _stockColor(product.totalStock, cs, tokens).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.totalStock != null
                              ? 'Stock: ${product.totalStock}'
                              : 'Sin stock',
                          style: TextStyle(color: _stockColor(product.totalStock, cs, tokens),
                              fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (product.attrList.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4, runSpacing: 2,
                        children: product.attrList.take(2).map((attr) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: tokens.surfaceAlt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(attr.trim(),
                              style: TextStyle(color: cs.primary,
                                  fontSize: 9, fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppTokens tokens) {
    return Container(
      color: tokens.surfaceAlt,
      child: Center(
          child: Icon(Icons.inventory_2_outlined, size: 40, color: tokens.textSubtle)),
    );
  }
}
