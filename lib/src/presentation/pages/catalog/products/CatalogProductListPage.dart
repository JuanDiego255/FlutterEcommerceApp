import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogNavItem.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/ProductVariant.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/bloc/CatalogProductsBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/bloc/CatalogProductsEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/bloc/CatalogProductsState.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/FullScreenImagePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      child: _CatalogProductListView(item: item, isDept: isDept, initialSearch: search),
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
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

  SliverAppBar _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cs.onBackground),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.item.id < 0 ? 'Resultados' : widget.item.name,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onBackground),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: (_) { _debounce?.cancel(); _search(); },
          style: TextStyle(fontSize: 14, color: cs.onBackground),
          decoration: InputDecoration(
            hintText: widget.item.id < 0
                ? 'Buscar en todo el catálogo...'
                : 'Buscar en ${widget.item.name}...',
            hintStyle: TextStyle(color: tokens.textSubtle, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: cs.primary, size: 20),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtrl,
              builder: (_, val, __) => val.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: 18, color: tokens.textMuted),
                      onPressed: () { _searchCtrl.clear(); _search(); },
                    )
                  : const SizedBox.shrink(),
            ),
            filled: true,
            fillColor: cs.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: cs.primary),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCategoryChips() {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: _loadingCategories
            ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
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
                        color: isSelected ? cs.primary : cs.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: isSelected ? cs.primary : cs.outline),
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? cs.onPrimary : cs.onBackground,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  SliverToBoxAdapter _buildAttrFilters() {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
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
                      color: cs.onBackground,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: cs.background, size: 12),
                        const SizedBox(width: 4),
                        Text('Limpiar', style: TextStyle(color: cs.background, fontSize: 12)),
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
                      color: _selectedAttrs.contains(value) ? cs.primary : cs.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: _selectedAttrs.contains(value) ? cs.primary : cs.outline,
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedAttrs.contains(value) ? FontWeight.w600 : FontWeight.w400,
                        color: _selectedAttrs.contains(value) ? cs.onPrimary : cs.onBackground,
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
        final cs = Theme.of(context).colorScheme;
        final tokens = Theme.of(context).extension<AppTokens>()!;
        if (state is CatalogProductsLoading || state is CatalogProductsInitial) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator(color: cs.primary)),
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
                  Icon(Icons.cloud_off_outlined, size: 48, color: tokens.textMuted),
                  const SizedBox(height: 12),
                  Text(state.message, style: TextStyle(fontSize: 12, color: tokens.textMuted), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
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
                    Icon(Icons.inventory_2_outlined, size: 48, color: tokens.textSubtle),
                    const SizedBox(height: 12),
                    Text('Sin productos disponibles', style: TextStyle(color: tokens.textMuted, fontSize: 14)),
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
              childAspectRatio: 0.60,
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
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
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
  final _wishlist = WishlistNotifier.instance;

  Future<void> _toggleWishlist() async {
    final p = widget.product;
    if (_wishlist.contains(p.id)) {
      await _wishlist.remove(p.id);
      return;
    }
    final attrs = p.availableAttrs;
    String? picked;
    if (attrs.length > 1) {
      picked = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => _VariantSheet(attrs: attrs),
      );
      if (picked == null) return;
    } else if (attrs.length == 1) {
      picked = attrs.first;
    }
    await _wishlist.add(WishlistItem(product: p, variantLabel: picked));
  }

  Future<void> _addToCart(BuildContext context) async {
    final p = widget.product;
    final attrs = p.availableAttrs;
    String? variantLabel;
    double? variantPrice;
    int? variantStock;
    int? variantManageStock;
    int? variantCombinationId;

    if (attrs.isNotEmpty) {
      List<ProductVariant> variants = [];
      final res = await MitaiApiService().getProductVariants(p.id);
      if (res is Success<List<ProductVariant>>) variants = res.data;

      if (attrs.length == 1 && variants.isEmpty) {
        variantLabel = attrs.first;
      } else {
        variantLabel = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _CartVariantSheet(attrGroups: p.attrGroups, defaultVariant: attrs.first),
        );
        if (variantLabel == null) return;
      }

      if (variantLabel != null && variants.isNotEmpty) {
        final matched = variants.where((v) => v.label == variantLabel).firstOrNull;
        if (matched != null) {
          if (matched.price > 0) variantPrice = matched.price;
          variantStock = matched.stock;
          variantManageStock = matched.manageStock;
          variantCombinationId = matched.combinationId > 0 ? matched.combinationId : null;
        }
      }
    }

    final cartProduct = Product(
      id: p.id,
      name: p.name,
      description: '',
      image1: p.imageUrl.isNotEmpty ? p.imageUrl : null,
      idCategory: 0,
      price: p.finalPrice,
      quantity: 1,
      selectedVariant: variantLabel,
      variantPrice: variantPrice,
      variantStock: variantStock,
      variantManageStock: variantManageStock,
      variantCombinationId: variantCombinationId,
    );
    await locator<ShoppingBagUseCases>().add.run(cartProduct);
    final allProducts = await locator<ShoppingBagUseCases>().getProducts.run();
    CartNotifier.instance.update(allProducts.length);

    if (!context.mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(variantLabel != null
            ? '${p.name} ($variantLabel) agregado al carrito'
            : '${p.name} agregado al carrito'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.surface,
        action: SnackBarAction(
          label: 'Ver carrito',
          textColor: cs.primary,
          onPressed: () => Navigator.pushNamed(context, 'client/shopping_bag'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return ListenableBuilder(
      listenable: _wishlist,
      builder: (context, _) {
        final inWishlist = _wishlist.contains(p.id);
        return _buildCard(context, p, inWishlist);
      },
    );
  }

  Widget _buildCard(BuildContext context, dynamic p, bool inWishlist) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
                    child: p.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                            placeholder: (_, __) => Container(color: tokens.surfaceAlt),
                            errorWidget: (_, __, ___) => _placeholder(tokens),
                          )
                        : _placeholder(tokens),
                  ),
                  if (p.hasDiscount)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary, borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text('-${p.discount}%',
                            style: TextStyle(color: cs.onPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: _toggleWishlist,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            inWishlist ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(inWishlist),
                            size: 16,
                            color: inWishlist ? cs.error : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (p.imageUrl.isNotEmpty)
                    Positioned(
                      bottom: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => FullScreenImagePage.show(context, [p.imageUrl]),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onBackground)),
                  const SizedBox(height: 4),
                  if (p.hasDiscount) ...[
                    Text('₡${fmtPrice(p.price)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.textSubtle,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: tokens.textSubtle,
                        )),
                    Text('₡${fmtPrice(p.finalPrice)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.error)),
                  ] else
                    Text('₡${fmtPrice(p.price)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _addToCart(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart, size: 12, color: cs.onPrimary),
                          const SizedBox(width: 4),
                          Text('Agregar', style: TextStyle(fontSize: 10, color: cs.onPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppTokens tokens) => Container(
        color: tokens.surfaceAlt,
        child: Center(child: Icon(Icons.image_outlined, size: 36, color: tokens.textSubtle)),
      );
}

// ─── Selectable attrs sheet ───────────────────────────────────────────────────

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
          Text('Atributos disponibles',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onBackground)),
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
                      Text(e.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: e.value.map((v) {
                          final isSel = _selected[e.key] == v;
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSel) _selected.remove(e.key); else _selected[e.key] = v;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? cs.primary : cs.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: isSel ? cs.primary : cs.primary.withOpacity(0.3)),
                              ),
                              child: Text(v, style: TextStyle(
                                  fontSize: 13,
                                  color: isSel ? cs.onPrimary : cs.primary,
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
              icon: const Icon(Icons.favorite, size: 16),
              label: const Text('Guardar en favoritos', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart variant picker sheet ────────────────────────────────────────────────

class _CartVariantSheet extends StatefulWidget {
  final Map<String, List<String>> attrGroups;
  final String defaultVariant;
  const _CartVariantSheet({required this.attrGroups, required this.defaultVariant});
  @override
  State<_CartVariantSheet> createState() => _CartVariantSheetState();
}

class _CartVariantSheetState extends State<_CartVariantSheet> {
  final Map<String, String> _selected = {};

  @override
  void initState() {
    super.initState();
    for (final e in widget.attrGroups.entries) {
      if (e.value.isNotEmpty) _selected[e.key] = e.value.first;
    }
  }

  String _buildLabel() {
    if (_selected.isEmpty) return widget.defaultVariant;
    return _selected.entries.map((e) => '${e.key}: ${e.value}').join(' / ');
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
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Seleccioná una variante',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onBackground)),
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
                      Text(e.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: e.value.map((v) {
                          final isSel = _selected[e.key] == v;
                          return GestureDetector(
                            onTap: () => setState(() => _selected[e.key] = v),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? cs.primary : cs.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: isSel ? cs.primary : cs.primary.withOpacity(0.3)),
                              ),
                              child: Text(v, style: TextStyle(
                                  fontSize: 13,
                                  color: isSel ? cs.onPrimary : cs.primary,
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
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('Agregar al carrito', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Simple variant sheet ─────────────────────────────────────────────────────

class _VariantSheet extends StatelessWidget {
  final List<String> attrs;
  const _VariantSheet({required this.attrs});
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
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Seleccioná una variante',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onBackground)),
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
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: cs.primary.withOpacity(0.3)),
                    ),
                    child: Text(a, style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600)),
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
