import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogNavItem.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/bloc/CatalogProductsBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/bloc/CatalogProductsEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/bloc/CatalogProductsState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kPrimary  = Color(0xFF2D2D2D);
const _kAccent   = Color(0xFF8B6F47);
const _kBg       = Color(0xFFFAFAFA);
const _kCard     = Colors.white;
const _kSub      = Color(0xFF757575);
const _kDivider  = Color(0xFFEEEEEE);

class CatalogProductListPage extends StatelessWidget {
  const CatalogProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final item = args['item'] as CatalogNavItem;
    final isDept = (args['is_department'] as bool?) ?? false;
    final search = (args['search'] as String?) ?? '';
    return BlocProvider(
      create: (_) => CatalogProductsBloc(CatalogService()),
      child: _CatalogProductListView(
        item: item,
        isDept: isDept,
        initialSearch: search,
      ),
    );
  }
}

class _CatalogProductListView extends StatefulWidget {
  final CatalogNavItem item;
  final bool isDept;
  final String initialSearch;

  const _CatalogProductListView({
    required this.item,
    required this.isDept,
    required this.initialSearch,
  });

  @override
  State<_CatalogProductListView> createState() => _CatalogProductListViewState();
}

class _CatalogProductListViewState extends State<_CatalogProductListView> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _service = CatalogService();

  List<CatalogNavItem> _subCategories = [];
  CatalogNavItem? _selectedCategory;
  bool _loadingCategories = false;
  bool _loadMoreTriggered = false;

  // Attribute filters
  List<Map<String, dynamic>> _attrGroups = [];
  final Set<String> _selectedAttrs = {};
  bool _loadingAttrs = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialSearch;
    _scrollCtrl.addListener(_onScroll);

    if (widget.isDept) {
      _loadCategories();
    } else if (widget.item.id < 0) {
      _loadProducts(0, search: widget.initialSearch);
    } else {
      _loadProducts(widget.item.id, search: widget.initialSearch);
      _loadAttributes(widget.item.id);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_loadMoreTriggered) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      final state = context.read<CatalogProductsBloc>().state;
      if (state is CatalogProductsLoaded && state.hasMore) {
        _loadMoreTriggered = true;
        context.read<CatalogProductsBloc>().add(CatalogProductsLoadMore());
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final result = await _service.getCategoriesByDepartment(widget.item.id);
    if (!mounted) return;
    if (result is Success) {
      final cats = (result as Success<List<CatalogNavItem>>).data!;
      setState(() {
        _subCategories = cats;
        _loadingCategories = false;
        if (cats.isNotEmpty) {
          _selectedCategory = cats.first;
          _loadProducts(cats.first.id, search: widget.initialSearch);
          _loadAttributes(cats.first.id);
        }
      });
    } else {
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadAttributes(int categoryId) async {
    setState(() { _loadingAttrs = true; _attrGroups = []; _selectedAttrs.clear(); });
    final result = await _service.getAttributesByCategory(categoryId);
    if (!mounted) return;
    if (result is Success<List<dynamic>>) {
      final groups = result.data
          .whereType<Map<String, dynamic>>()
          .where((g) {
            final vals = g['values'] as List<dynamic>?;
            return vals != null && vals.isNotEmpty;
          })
          .toList();
      setState(() { _attrGroups = groups; _loadingAttrs = false; });
    } else {
      setState(() => _loadingAttrs = false);
    }
  }

  void _loadProducts(int categoryId, {String search = '', List<String>? attrValues}) {
    _loadMoreTriggered = false;
    context.read<CatalogProductsBloc>().add(
      CatalogProductsLoad(
        categoryId: categoryId,
        search: search,
        attrValues: attrValues ?? _selectedAttrs.toList(),
      ),
    );
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  void _search() {
    final q = _searchCtrl.text.trim();
    final catId = widget.item.id < 0 ? 0 : (_selectedCategory?.id ?? widget.item.id);
    _loadProducts(catId, search: q);
  }

  void _toggleAttr(String value) {
    setState(() {
      if (_selectedAttrs.contains(value)) {
        _selectedAttrs.remove(value);
      } else {
        _selectedAttrs.add(value);
      }
    });
    final catId = _selectedCategory?.id ?? widget.item.id;
    _loadProducts(catId, search: _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildAppBar(),
          _buildSearchBar(),
          if (widget.isDept && (_loadingCategories || _subCategories.isNotEmpty))
            _buildCategoryChips(),
          if (_attrGroups.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            _buildAttrFilters(),
          ],
          _buildProductGrid(),
          _buildLoadMoreIndicator(),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
        pinned: true,
        backgroundColor: _kCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: _kDivider,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item.id < 0 ? 'Resultados' : widget.item.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      );

  SliverToBoxAdapter _buildSearchBar() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) {
              _debounce?.cancel();
              _search();
            },
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.item.id < 0
                  ? 'Buscar en todo el catálogo...'
                  : 'Buscar en ${widget.item.name}...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: _kAccent, size: 20),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchCtrl,
                builder: (_, val, __) => val.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search();
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kAccent),
              ),
            ),
          ),
        ),
      );

  SliverToBoxAdapter _buildCategoryChips() => SliverToBoxAdapter(
        child: SizedBox(
          height: 44,
          child: _loadingCategories
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _subCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _subCategories[i];
                    final isSelected = cat.id == _selectedCategory?.id;
                    return GestureDetector(
                      onTap: () {
                        if (cat.id == _selectedCategory?.id) return;
                        setState(() => _selectedCategory = cat);
                        _loadProducts(cat.id, search: _searchCtrl.text.trim());
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _kAccent : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _kAccent : _kDivider,
                          ),
                        ),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : _kPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      );

  SliverToBoxAdapter _buildAttrFilters() {
    final allValues = <String>[];
    for (final g in _attrGroups) {
      final vals = (g['values'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((v) => v['value']?.toString() ?? '')
          .where((v) => v.isNotEmpty)
          .toList();
      allValues.addAll(vals);
    }
    if (allValues.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (_selectedAttrs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedAttrs.clear());
                    final catId = _selectedCategory?.id ?? widget.item.id;
                    _loadProducts(catId, search: _searchCtrl.text.trim(), attrValues: []);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Limpiar', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            for (final value in allValues)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => _toggleAttr(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedAttrs.contains(value) ? _kAccent : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedAttrs.contains(value) ? _kAccent : _kDivider,
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedAttrs.contains(value)
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedAttrs.contains(value) ? Colors.white : _kPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return BlocConsumer<CatalogProductsBloc, CatalogProductsState>(
      listener: (context, state) {
        if (state is CatalogProductsLoaded || state is CatalogProductsError) {
          _loadMoreTriggered = false;
        }
      },
      builder: (context, state) {
        if (state is CatalogProductsLoading || state is CatalogProductsInitial) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator(color: _kAccent)),
            ),
          );
        }

        if (state is CatalogProductsError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48, color: _kSub),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 12, color: _kSub),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _search,
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        List<CatalogProduct> products = [];
        if (state is CatalogProductsLoaded) products = state.products;
        if (state is CatalogProductsLoadingMore) products = state.products;

        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Sin productos disponibles',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ProductCard(
                product: products[i],
                onTap: () => Navigator.pushNamed(
                  context,
                  'catalog/product/detail',
                  arguments: {'product': products[i]},
                ),
              ),
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() =>
      BlocBuilder<CatalogProductsBloc, CatalogProductsState>(
        builder: (context, state) {
          if (state is CatalogProductsLoadingMore) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
                ),
              ),
            );
          }
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        },
      );
}

// ─── Product card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final CatalogProduct product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});
  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _inWishlist = false;

  @override
  void initState() {
    super.initState();
    WishlistService.contains(widget.product.id)
        .then((v) { if (mounted) setState(() => _inWishlist = v); });
  }

  Future<void> _toggleWishlist() async {
    final p = widget.product;
    if (_inWishlist) {
      await WishlistService.remove(p.id);
      if (mounted) setState(() => _inWishlist = false);
      return;
    }
    final attrs = p.availableAttrs;
    String? picked;
    if (attrs.length > 1) {
      picked = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _VariantSheet(attrs: attrs),
      );
      if (picked == null) return;
    } else if (attrs.length == 1) {
      picked = attrs.first;
    }
    await WishlistService.add(WishlistItem(product: p, variantLabel: picked));
    if (mounted) setState(() => _inWishlist = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: p.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                            placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  if (p.hasDiscount)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('-${p.discount}%',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: _toggleWishlist,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            _inWishlist ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(_inWishlist),
                            size: 16,
                            color: _inWishlist ? const Color(0xFFE53935) : _kSub,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  if (p.hasDiscount) ...[
                    Text('₡${fmtPrice(p.price)}',
                        style: const TextStyle(fontSize: 10, color: _kSub, decoration: TextDecoration.lineThrough)),
                    Text('₡${fmtPrice(p.finalPrice)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE53935))),
                  ] else
                    Text('₡${fmtPrice(p.price)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent)),
                  if (p.attrGroups.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => _SelectableAttrsSheet(attrGroups: p.attrGroups),
                        );
                        if (!mounted || picked == null) return;
                        if (_inWishlist) await WishlistService.remove(p.id);
                        await WishlistService.add(WishlistItem(product: p, variantLabel: picked));
                        if (mounted) setState(() => _inWishlist = true);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kAccent.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.style_outlined, size: 11, color: _kAccent),
                            SizedBox(width: 4),
                            Text('Ver atributos',
                                style: TextStyle(fontSize: 10, color: _kAccent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(child: Icon(Icons.image_outlined, size: 36, color: Color(0xFFBDBDBD))),
      );
}

class _SelectableAttrsSheet extends StatefulWidget {
  final Map<String, List<String>> attrGroups;
  const _SelectableAttrsSheet({required this.attrGroups});
  @override
  State<_SelectableAttrsSheet> createState() => _SelectableAttrsSheetState();
}

class _SelectableAttrsSheetState extends State<_SelectableAttrsSheet> {
  final Map<String, String> _selected = {};

  String _buildLabel() {
    if (_selected.isEmpty) {
      final first = widget.attrGroups.entries.first;
      return '${first.key}: ${first.value.first}';
    }
    return _selected.entries.map((e) => '${e.key}: ${e.value}').join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Atributos disponibles',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.attrGroups.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: _kSub)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: e.value.map((v) {
                          final isSel = _selected[e.key] == v;
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSel) {
                                _selected.remove(e.key);
                              } else {
                                _selected[e.key] = v;
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? _kAccent : const Color(0xFFF5F0EB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _kAccent.withOpacity(isSel ? 1.0 : 0.3)),
                              ),
                              child: Text(v,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isSel ? Colors.white : _kAccent,
                                      fontWeight: FontWeight.w600)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _buildLabel()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.favorite, size: 16),
              label: const Text('Guardar en favoritos',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantSheet extends StatelessWidget {
  final List<String> attrs;
  const _VariantSheet({required this.attrs});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Seleccioná una variante',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: attrs.map((a) => GestureDetector(
                    onTap: () => Navigator.pop(context, a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0EB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kAccent.withOpacity(0.3)),
                      ),
                      child: Text(a,
                          style: const TextStyle(fontSize: 13, color: _kAccent, fontWeight: FontWeight.w600)),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      );
}
