import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogNavItem.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
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

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialSearch;
    _scrollCtrl.addListener(_onScroll);

    if (widget.isDept) {
      _loadCategories();
    } else {
      _loadProducts(widget.item.id, search: widget.initialSearch);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
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
        }
      });
    } else {
      setState(() => _loadingCategories = false);
    }
  }

  void _loadProducts(int categoryId, {String search = ''}) {
    _loadMoreTriggered = false;
    context.read<CatalogProductsBloc>().add(
      CatalogProductsLoad(categoryId: categoryId, search: search),
    );
  }

  void _search() {
    final q = _searchCtrl.text.trim();
    final catId = _selectedCategory?.id ?? widget.item.id;
    _loadProducts(catId, search: q);
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
          widget.item.name,
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
            onSubmitted: (_) => _search(),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar en ${widget.item.name}...',
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
              childAspectRatio: 0.72,
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

// ─── Product card (mirrors CatalogHomePage._ProductCard) ─────────────────────

class _ProductCard extends StatelessWidget {
  final CatalogProduct product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: const Color(0xFFF5F5F5)),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (product.hasDiscount) ...[
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ] else
                    Text(
                      '₡${_fmt(product.price)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kAccent,
                      ),
                    ),
                  if (product.availableAttrs.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.availableAttrs.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: _kSub),
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
        child: const Center(
          child: Icon(Icons.image_outlined, size: 36, color: Color(0xFFBDBDBD)),
        ),
      );

  String _fmt(double v) {
    if (v == v.truncate()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
