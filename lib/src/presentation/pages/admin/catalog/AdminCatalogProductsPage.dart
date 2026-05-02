import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/MitaiProduct.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminProductDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminProductFormPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kBg         = Color(0xFFFAF8F5);
const Color _kPrimary    = Color(0xFF8B6F47);
const Color _kAccent     = Color(0xFFC8966A);
const Color _kSurface    = Color(0xFFFFFFFF);
const Color _kTextPrimary   = Color(0xFF1A1A1A);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kStockOk    = Color(0xFF22C55E);
const Color _kStockLow   = Color(0xFFF59E0B);
const Color _kStockOut   = Color(0xFFEF4444);

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

  // Full product list (current page)
  List<MitaiProduct> _products = [];

  // Filters
  String _search      = '';
  String? _attrFilter;

  // Pagination
  bool _loading    = true;
  bool _loadingMore = false;
  String? _error;
  int  _currentPage = 1;
  int  _lastPage    = 1;
  int  _total       = 0;
  static const _perPage = 15;

  // Attributes derived from loaded products
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

      // Collect unique attribute names for filter chips
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${product.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kStockOut),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${(result).message}'),
          backgroundColor: _kStockOut,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(widget.categoryName,
            style: const TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: _kPrimary),
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
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_availableAttrs.isNotEmpty) _buildAttrFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          if (v.length >= 2 || v.isEmpty) _onSearch(v);
        },
        onSubmitted: _onSearch,
        style: const TextStyle(fontSize: 14, color: _kTextPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o código...',
          hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _kPrimary, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: _kTextSecondary, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF0EBE3),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildAttrFilter() {
    return Container(
      color: _kSurface,
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
              selectedColor: _kPrimary,
              labelStyle: TextStyle(color: _attrFilter == null ? Colors.white : _kTextPrimary),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }
          final attr = _availableAttrs[i - 1];
          final sel  = _attrFilter == attr;
          return FilterChip(
            label: Text(attr, style: TextStyle(fontSize: 11, color: sel ? Colors.white : _kTextPrimary)),
            selected: sel,
            onSelected: (_) => setState(() => _attrFilter = sel ? null : attr),
            selectedColor: _kPrimary,
            backgroundColor: const Color(0xFFF0EBE3),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(reset: true),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
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
            const Icon(Icons.search_off, size: 56, color: _kAccent),
            const SizedBox(height: 12),
            Text(
              _search.isNotEmpty ? 'Sin resultados para "$_search"' : 'No hay productos en esta categoría',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Total count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text('$_total producto${_total == 1 ? '' : 's'}',
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
              const Spacer(),
              if (_search.isNotEmpty)
                Text('Mostrando ${visible.length} resultado${visible.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadData(reset: true),
            color: _kPrimary,
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
                  // Load more trigger
                  if (!_loadingMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                  }
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)));
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

  Color _stockColor(int? stock) {
    if (stock == null || stock == 0) return _kStockOut;
    if (stock <= 5) return _kStockLow;
    return _kStockOk;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
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
                            placeholder: (_, __) => Container(color: const Color(0xFFF0EBE3),
                                child: const Center(child: CircularProgressIndicator(
                                    color: _kAccent, strokeWidth: 2))),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                    // Delete button overlay
                    Positioned(
                      top: 4, left: 4,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                          ),
                          child: const Icon(Icons.delete_outline, size: 14, color: _kStockOut),
                        ),
                      ),
                    ),
                    // Edit button overlay
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                          ),
                          child: const Icon(Icons.edit, size: 14, color: _kPrimary),
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
                        style: const TextStyle(color: _kTextPrimary,
                            fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('₡${currencyFormat.format(product.price)}',
                        style: const TextStyle(color: _kPrimary,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const Spacer(),
                    if (product.manageStock == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _stockColor(product.totalStock).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.totalStock != null
                              ? 'Stock: ${product.totalStock}'
                              : 'Sin stock',
                          style: TextStyle(color: _stockColor(product.totalStock),
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
                            color: const Color(0xFFF0EBE3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(attr.trim(),
                              style: const TextStyle(color: _kAccent,
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

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF0EBE3),
      child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 40, color: _kAccent)),
    );
  }
}
