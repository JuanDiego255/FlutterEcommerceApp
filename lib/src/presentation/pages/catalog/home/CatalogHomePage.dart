import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogHomeData.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogNavItem.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/bloc/CatalogHomeBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/bloc/CatalogHomeEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/bloc/CatalogHomeState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kPrimary  = Color(0xFF2D2D2D);
const _kAccent   = Color(0xFF8B6F47);
const _kBg       = Color(0xFFFAFAFA);
const _kCard     = Colors.white;
const _kSub      = Color(0xFF757575);
const _kDivider  = Color(0xFFEEEEEE);

class CatalogHomePage extends StatelessWidget {
  const CatalogHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CatalogHomeBloc(CatalogService())..add(CatalogHomeLoad()),
      child: const _CatalogHomeView(),
    );
  }
}

class _CatalogHomeView extends StatefulWidget {
  const _CatalogHomeView();

  @override
  State<_CatalogHomeView> createState() => _CatalogHomeViewState();
}

class _CatalogHomeViewState extends State<_CatalogHomeView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: BlocBuilder<CatalogHomeBloc, CatalogHomeState>(
        builder: (context, state) {
          if (state is CatalogHomeLoading || state is CatalogHomeInitial) {
            return const _LoadingView();
          }
          if (state is CatalogHomeError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<CatalogHomeBloc>().add(CatalogHomeLoad()),
            );
          }
          if (state is CatalogHomeLoaded) {
            return _ContentView(
              data: state.data,
              searchCtrl: _searchCtrl,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Content view ─────────────────────────────────────────────────────────────

class _ContentView extends StatefulWidget {
  final CatalogHomeData data;
  final TextEditingController searchCtrl;

  const _ContentView({required this.data, required this.searchCtrl});

  @override
  State<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<_ContentView> {
  int _selectedNavIdx = 0;

  CatalogHomeData get data => widget.data;

  void _openProducts(CatalogNavItem item, {bool isDept = false}) {
    Navigator.pushNamed(
      context,
      'catalog/products',
      arguments: {
        'item': item,
        'is_department': isDept,
      },
    );
  }

  void _search() {
    final q = widget.searchCtrl.text.trim();
    if (q.isEmpty) return;
    // Navigate to first nav item's products with search, or all if no nav
    if (data.navItems.isEmpty) return;
    Navigator.pushNamed(
      context,
      'catalog/products',
      arguments: {
        'item': data.navItems.first,
        'is_department': data.navType == 'departments',
        'search': q,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        if (data.tenantInfo.cintillo && data.tenantInfo.textCintillo != null)
          _buildCintillo(),
        _buildSearchBar(),
        _buildNavSection(),
        _buildFeaturedSection(),
        _buildFooter(),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ─── App bar with logo + title + admin button ─────────────────────────────

  SliverAppBar _buildAppBar() {
    final info = data.tenantInfo;
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kCard,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: _kDivider,
      title: Row(
        children: [
          if (info.logoUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: info.logoUrl,
                height: 36,
                width: 36,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              info.title.isNotEmpty ? info.title : TenantSession.host,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (info.whatsapp != null && info.whatsapp!.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
            tooltip: 'WhatsApp',
            onPressed: () => _launchUrl(info.whatsappUrl),
          ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: _kAccent, size: 22),
          tooltip: 'Favoritos',
          onPressed: () => Navigator.pushNamed(context, 'catalog/wishlist'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _kSub, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'admin') {
              Navigator.pushNamed(
                context,
                TenantSession.hasAdminAccess ? 'login' : 'admin/token',
              );
            } else if (value == 'change') {
              Navigator.pushReplacementNamed(context, 'tenant/select');
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'admin',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined, size: 18, color: _kAccent),
                  SizedBox(width: 10),
                  Text('Panel admin', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_outlined, size: 18, color: _kSub),
                  SizedBox(width: 10),
                  Text('Cambiar tienda', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Announcement banner ──────────────────────────────────────────────────

  SliverToBoxAdapter _buildCintillo() => SliverToBoxAdapter(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _kPrimary,
      child: Text(
        data.tenantInfo.textCintillo!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  // ─── Search bar ───────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildSearchBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: widget.searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _kAccent, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.searchCtrl,
            builder: (_, val, __) => val.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                    onPressed: () => widget.searchCtrl.clear(),
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

  // ─── Navigation (categories or departments) ───────────────────────────────

  SliverToBoxAdapter _buildNavSection() {
    if (data.navItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              data.navType == 'departments' ? 'Departamentos' : 'Categorías',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: data.navItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = data.navItems[i];
                final isSelected = i == _selectedNavIdx;
                return _NavChip(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedNavIdx = i);
                    _openProducts(item, isDept: data.navType == 'departments');
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Featured products section ────────────────────────────────────────────

  SliverToBoxAdapter _buildFeaturedSection() {
    if (data.featured.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Destacados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: data.featured.length,
            itemBuilder: (_, i) => _ProductCard(
              product: data.featured[i],
              onTap: () => Navigator.pushNamed(
                context,
                'catalog/product/detail',
                arguments: {'product': data.featured[i]},
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildFooter() {
    final info = data.tenantInfo;
    final hasSocial = data.social.isNotEmpty;
    final hasContact = (info.email?.isNotEmpty ?? false) ||
        (info.whatsapp?.isNotEmpty ?? false);
    if (!hasSocial && !hasContact && (info.footer?.isEmpty ?? true)) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.title.isNotEmpty)
              Text(
                info.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (info.footer?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text(
                info.footer!,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            ],
            if (hasContact) ...[
              const SizedBox(height: 12),
              if (info.whatsapp?.isNotEmpty ?? false)
                _FooterLink(
                  icon: Icons.chat_outlined,
                  label: info.whatsapp!,
                  color: const Color(0xFF25D366),
                  onTap: () => _launchUrl(info.whatsappUrl),
                ),
              if (info.email?.isNotEmpty ?? false)
                _FooterLink(
                  icon: Icons.email_outlined,
                  label: info.email!,
                  color: Colors.white70,
                  onTap: () => _launchUrl('mailto:${info.email}'),
                ),
            ],
            if (hasSocial) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.social
                    .where((s) => s.url?.isNotEmpty ?? false)
                    .map((s) => GestureDetector(
                          onTap: () => _launchUrl(s.url!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl(
                  'https://${TenantSession.host}/privacy-policy'),
              child: Text(
                'Política de privacidad',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Nav chip ──────────────────────────────────────────────────────────────────

class _NavChip extends StatelessWidget {
  final CatalogNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavChip({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? _kAccent.withOpacity(0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _kAccent : _kDivider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: item.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _categoryIcon(isSelected),
                      ),
                    )
                  : _categoryIcon(isSelected),
            ),
            const SizedBox(height: 4),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _kAccent : _kSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryIcon(bool selected) => Icon(
        Icons.category_outlined,
        size: 22,
        color: selected ? _kAccent : _kSub,
      );
}

// ─── Product card ─────────────────────────────────────────────────────────────

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
            // Image
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
                            placeholder: (_, __) => Container(
                                color: const Color(0xFFF5F5F5)),
                            errorWidget: (_, __, ___) =>
                                _placeholderImage(),
                          )
                        : _placeholderImage(),
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
            // Info
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
                      style: const TextStyle(
                          fontSize: 10, color: _kSub),
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

  Widget _placeholderImage() => Container(
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

// ─── Footer link ──────────────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FooterLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading / error views ────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _kBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kAccent),
            SizedBox(height: 16),
            Text('Cargando catálogo...',
                style: TextStyle(color: _kSub, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: _kSub),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar el catálogo',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message,
                  style: const TextStyle(fontSize: 12, color: _kSub),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
