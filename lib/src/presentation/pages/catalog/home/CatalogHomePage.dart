import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MitaiApiService.dart';
import 'package:ecommerce_flutter/src/domain/models/Product.dart';
import 'package:ecommerce_flutter/src/domain/models/ProductVariant.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CatalogService.dart';
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/Order.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogHomeData.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogNavItem.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/CatalogProduct.dart';
import 'package:ecommerce_flutter/src/domain/models/catalog/WishlistItem.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/domain/utils/PriceFormatter.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/bloc/CatalogHomeBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/bloc/CatalogHomeEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/bloc/CatalogHomeState.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/ClientOrderListItem.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/bloc/ClientOrderListState.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/wishlist/WishlistPage.dart';
import 'package:ecommerce_flutter/src/presentation/widgets/FullScreenImagePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

// Virtual "Inicio" nav item (id < 0 → never maps to a real category)
final _kHomeNavItem = CatalogNavItem(id: -1, name: 'Inicio', image: null);

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
      child: const _CatalogShell(),
    );
  }
}

// ─── Shell: owns BottomNav + auth state ───────────────────────────────────────

class _CatalogShell extends StatefulWidget {
  const _CatalogShell();

  @override
  State<_CatalogShell> createState() => _CatalogShellState();
}

class _CatalogShellState extends State<_CatalogShell> {
  int _navIndex = 0;
  AuthResponse? _authSession;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _reloadCartCount();
    // Navigate to a specific tab if passed as route argument (e.g., {'tab': 2} from checkout)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final tab = args['tab'] as int?;
        if (tab != null && tab != _navIndex) _onNavTap(tab);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final session = await locator<AuthUseCases>().getUserSession.run();
    if (mounted) setState(() => _authSession = session);
  }

  Future<void> _reloadCartCount() async {
    final products = await locator<ShoppingBagUseCases>().getProducts.run();
    CartNotifier.instance.update(products.length);
  }

  Future<void> _logout() async {
    await locator<AuthUseCases>().logout.run();
    await SecureStorageService.clearAll();
    CartNotifier.instance.update(0);
    if (!mounted) return;
    setState(() {
      _authSession = null;
      _navIndex = 0;
    });
  }

  bool get _isLoggedIn => _authSession != null;

  void _onNavTap(int i) {
    if (i == 2 && !_isLoggedIn) {
      Navigator.pushNamed(context, 'login').then((_) => _checkAuth());
      return;
    }
    if (i == 2 && _isLoggedIn && _navIndex != 2) {
      context.read<ClientOrderListBloc>().add(GetOrders());
    }
    if (_navIndex != i) setState(() => _navIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _CatalogTab(searchCtrl: _searchCtrl, authSession: _authSession, onAuthChanged: _checkAuth),
          _CategoriesTab(onAuthChanged: _checkAuth),
          _AccountTab(authSession: _authSession, onLogout: _logout, onLoginTap: () {
            Navigator.pushNamed(context, 'login').then((_) {
              _checkAuth();
              setState(() => _navIndex = 2);
            });
          }),
          const WishlistPage(embedded: true),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BlocBuilder<CatalogHomeBloc, CatalogHomeState>(
      buildWhen: (prev, curr) => curr is CatalogHomeLoaded || curr is CatalogHomeInitial,
      builder: (context, catalogState) {
        final navLabel = (catalogState is CatalogHomeLoaded &&
                catalogState.data.navType == 'departments')
            ? 'Departamentos'
            : 'Categorías';
        final navIcon = (catalogState is CatalogHomeLoaded &&
                catalogState.data.navType == 'departments')
            ? Icons.store_outlined
            : Icons.category_outlined;
        final navIconActive = (catalogState is CatalogHomeLoaded &&
                catalogState.data.navType == 'departments')
            ? Icons.store
            : Icons.category;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _navIndex,
            onTap: _onNavTap,
            backgroundColor: Colors.white,
            selectedItemColor: _kAccent,
            unselectedItemColor: const Color(0xFF9E9E9E),
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(navIcon),
                activeIcon: Icon(navIconActive),
                label: navLabel,
              ),
              BottomNavigationBarItem(
                icon: Icon(_isLoggedIn
                    ? Icons.receipt_long_outlined
                    : Icons.person_outline),
                activeIcon:
                    Icon(_isLoggedIn ? Icons.receipt_long : Icons.person),
                label: _isLoggedIn ? 'Mis pedidos' : 'Mi cuenta',
              ),
              BottomNavigationBarItem(
                icon: AnimatedBuilder(
                  animation: WishlistNotifier.instance,
                  builder: (_, __) {
                    final count = WishlistNotifier.instance.count;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.favorite_border),
                        if (count > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                  color: _kAccent, shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                activeIcon: AnimatedBuilder(
                  animation: WishlistNotifier.instance,
                  builder: (_, __) {
                    final count = WishlistNotifier.instance.count;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.favorite),
                        if (count > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                  color: _kAccent, shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                label: 'Favoritos',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab 0: Catalog home ──────────────────────────────────────────────────────

class _CatalogTab extends StatelessWidget {
  final TextEditingController searchCtrl;
  final AuthResponse? authSession;
  final VoidCallback onAuthChanged;

  const _CatalogTab({required this.searchCtrl, this.authSession, required this.onAuthChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogHomeBloc, CatalogHomeState>(
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
            searchCtrl: searchCtrl,
            authSession: authSession,
            onAuthChanged: onAuthChanged,
          );
        }
        return const _LoadingView();
      },
    );
  }
}

// ─── Tab 1: Categories browser ────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final VoidCallback onAuthChanged;

  const _CategoriesTab({required this.onAuthChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogHomeBloc, CatalogHomeState>(
      builder: (context, state) {
        if (state is CatalogHomeLoaded) {
          return _CategoriesView(data: state.data);
        }
        return const _LoadingView();
      },
    );
  }
}

class _CategoriesView extends StatelessWidget {
  final CatalogHomeData data;

  const _CategoriesView({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.navItems;
    final isDept = data.navType == 'departments';
    final label = isDept ? 'Departamentos' : 'Categorías';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _kCard,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: _kDivider,
          title: Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('No hay categorías disponibles', style: TextStyle(color: _kSub)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _CategoryGridCard(item: items[i], isDept: isDept),
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final CatalogNavItem item;
  final bool isDept;

  const _CategoryGridCard({required this.item, required this.isDept});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        'catalog/products',
        arguments: {'item': item, 'is_department': isDept},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kDivider),
              ),
              child: item.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.category_outlined, size: 28, color: _kAccent),
                      ),
                    )
                  : const Icon(Icons.category_outlined, size: 28, color: _kAccent),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Account (orders if logged in, login prompt if not) ────────────────

class _AccountTab extends StatefulWidget {
  final AuthResponse? authSession;
  final VoidCallback onLoginTap;
  final VoidCallback onLogout;

  const _AccountTab({this.authSession, required this.onLoginTap, required this.onLogout});

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  @override
  void didUpdateWidget(_AccountTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authSession == null && widget.authSession != null) {
      // Just logged in — load orders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ClientOrderListBloc>().add(GetOrders());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authSession == null) {
      return _buildLoginPrompt(context);
    }
    return _buildOrdersView(context);
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 48, color: _kAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mis pedidos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Iniciá sesión para ver el historial de tus pedidos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onLoginTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Iniciar sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, 'register'),
              child: const Text('¿No tenés cuenta? Registrate', style: TextStyle(color: _kAccent, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersView(BuildContext context) {
    final roles = widget.authSession?.user.roles ?? [];
    final adminIdx = roles.indexWhere((r) => r.route.contains('admin'));
    final adminRole = adminIdx >= 0 ? roles[adminIdx] : null;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            child: Row(
              children: [
                const Text(
                  'Mis pedidos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_outlined, color: _kAccent),
                  tooltip: 'Actualizar',
                  onPressed: () => context.read<ClientOrderListBloc>().add(GetOrders()),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: _kAccent),
                  onSelected: (value) {
                    if (value == 'logout') {
                      widget.onLogout();
                    } else if (value == 'admin' && adminRole != null) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, adminRole.route, (route) => false);
                    }
                  },
                  itemBuilder: (_) => [
                    if (adminRole != null)
                      const PopupMenuItem(
                        value: 'admin',
                        child: Row(children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 18, color: _kAccent),
                          SizedBox(width: 8),
                          Text('Panel Admin'),
                        ]),
                      ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          // Orders list
          Expanded(
            child: BlocListener<ClientOrderListBloc, ClientOrderListState>(
              listener: (context, state) {
                if (state.response is Error) {
                  Fluttertoast.showToast(
                    msg: (state.response as Error).message,
                    toastLength: Toast.LENGTH_LONG,
                  );
                }
              },
              child: BlocBuilder<ClientOrderListBloc, ClientOrderListState>(
                builder: (context, state) {
                  final resp = state.response;
                  if (resp is Loading) {
                    return const Center(child: CircularProgressIndicator(color: _kAccent));
                  }
                  if (resp is Success) {
                    final orders = resp.data as List<Order>;
                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No tenés pedidos aún',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text('Tus pedidos aparecerán aquí',
                                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: _kAccent,
                      onRefresh: () async => context.read<ClientOrderListBloc>().add(GetOrders()),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: orders.length,
                        itemBuilder: (_, i) => ClientOrderListItem(orders[i]),
                      ),
                    );
                  }
                  if (resp is Error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text((resp).message,
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => context.read<ClientOrderListBloc>().add(GetOrders()),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator(color: _kAccent));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Content view (Tab 0 loaded state) ───────────────────────────────────────

class _ContentView extends StatefulWidget {
  final CatalogHomeData data;
  final TextEditingController searchCtrl;
  final AuthResponse? authSession;
  final VoidCallback onAuthChanged;

  const _ContentView({
    required this.data,
    required this.searchCtrl,
    this.authSession,
    required this.onAuthChanged,
  });

  @override
  State<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<_ContentView> {
  int _selectedNavIdx = 0;

  CatalogHomeData get data => widget.data;
  AuthResponse? get _authSession => widget.authSession;

  void _openProducts(CatalogNavItem item, {bool isDept = false}) {
    Navigator.pushNamed(
      context,
      'catalog/products',
      arguments: {'item': item, 'is_department': isDept},
    ).then((_) {
      if (mounted) setState(() => _selectedNavIdx = 0);
    });
  }

  void _doSearch(String q) {
    q = q.trim();
    if (q.isEmpty) return;
    Navigator.pushNamed(
      context,
      'catalog/products',
      arguments: {
        'item': const CatalogNavItem(id: -1, name: 'Resultados'),
        'is_department': false,
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
        ..._buildFeaturedSlivers(),
        _buildFooter(),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ─── App bar ──────────────────────────────────────────────────────────────

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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Refresh catalog
        IconButton(
          icon: const Icon(Icons.refresh_outlined, color: _kSub, size: 22),
          tooltip: 'Actualizar catálogo',
          onPressed: () => context.read<CatalogHomeBloc>().add(CatalogHomeLoad()),
        ),
        // Cart icon with badge
        ValueListenableBuilder<int>(
          valueListenable: CartNotifier.instance,
          builder: (_, count, __) => Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: _kPrimary, size: 22),
                tooltip: 'Carrito',
                onPressed: () => Navigator.pushNamed(context, 'client/shopping_bag'),
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _kSub, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'login_client') {
              Navigator.pushNamed(context, 'login').then((_) => widget.onAuthChanged());
            } else if (value == 'admin') {
              if (widget.authSession != null) {
                Navigator.pushNamedAndRemoveUntil(context, 'admin/home', (route) => false);
              } else {
                Navigator.pushNamed(context, TenantSession.hasAdminAccess ? 'login' : 'admin/token');
              }
            } else if (value == 'change') {
              Navigator.pushReplacementNamed(context, 'tenant/select');
            }
          },
          itemBuilder: (_) => [
            if (_authSession == null)
              const PopupMenuItem(
                value: 'login_client',
                child: Row(children: [
                  Icon(Icons.login_outlined, size: 18, color: _kAccent),
                  SizedBox(width: 10),
                  Text('Iniciar sesión', style: TextStyle(fontSize: 13)),
                ]),
              ),
            const PopupMenuItem(
              value: 'admin',
              child: Row(children: [
                Icon(Icons.admin_panel_settings_outlined, size: 18, color: _kAccent),
                SizedBox(width: 10),
                Text('Panel admin', style: TextStyle(fontSize: 13)),
              ]),
            ),
            const PopupMenuItem(
              value: 'change',
              child: Row(children: [
                Icon(Icons.swap_horiz_outlined, size: 18, color: _kSub),
                SizedBox(width: 10),
                Text('Cambiar tienda', style: TextStyle(fontSize: 13)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Cintillo ─────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildCintillo() => SliverToBoxAdapter(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _kPrimary,
      child: Text(
        data.tenantInfo.textCintillo!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
        onSubmitted: (_) => _doSearch(widget.searchCtrl.text),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: GestureDetector(
            onTap: () => _doSearch(widget.searchCtrl.text),
            child: const Icon(Icons.search, color: _kAccent, size: 20),
          ),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kAccent)),
        ),
      ),
    ),
  );

  // ─── Nav section ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildNavSection() {
    if (data.navItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final navAll = [_kHomeNavItem, ...data.navItems];
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              data.navType == 'departments' ? 'Departamentos' : 'Categorías',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: navAll.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = navAll[i];
                final isSelected = i == _selectedNavIdx;
                return _NavChip(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedNavIdx = i);
                    if (item.id >= 0) {
                      _openProducts(item, isDept: data.navType == 'departments');
                    }
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

  // ─── Featured products ────────────────────────────────────────────────────

  List<Widget> _buildFeaturedSlivers() {
    if (data.featured.isEmpty) return [];
    return [
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text('Destacados',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => _FeaturedCard(
              product: data.featured[i],
              onTap: () => Navigator.pushNamed(
                context,
                'catalog/product/detail',
                arguments: {'product': data.featured[i]},
              ).then((_) => setState(() {})),
            ),
            childCount: data.featured.length,
          ),
        ),
      ),
    ];
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildFooter() {
    final info = data.tenantInfo;
    final hasWa    = info.whatsapp?.isNotEmpty ?? false;
    final hasEmail = info.email?.isNotEmpty ?? false;
    final hasSocial = data.social.isNotEmpty;
    if (!hasSocial && !hasWa && !hasEmail && (info.footer?.isEmpty ?? true) && info.title.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 20, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF6B4F30), _kAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    if (info.logoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: info.logoUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                        ),
                      )
                    else
                      const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (info.title.isNotEmpty)
                            Text(info.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          if (info.footer?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 3),
                            Text(info.footer!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasWa || hasEmail) ...[
                      Row(
                        children: [
                          if (hasWa)
                            Expanded(child: _ContactChip(
                              icon: Icons.chat_rounded,
                              label: 'WhatsApp',
                              color: const Color(0xFF25D366),
                              onTap: () => _launchUrl(info.whatsappUrl),
                            )),
                          if (hasWa && hasEmail) const SizedBox(width: 10),
                          if (hasEmail)
                            Expanded(child: _ContactChip(
                              icon: Icons.email_rounded,
                              label: info.email!,
                              color: _kAccent,
                              onTap: () => _launchUrl('mailto:${info.email}'),
                            )),
                        ],
                      ),
                      if (hasSocial) const SizedBox(height: 12),
                    ],
                    if (hasSocial)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.social
                            .where((s) => s.url?.isNotEmpty ?? false)
                            .map((s) => GestureDetector(
                              onTap: () => _launchUrl(s.url!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F0EB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _kDivider),
                                ),
                                child: Text(s.name, style: const TextStyle(fontSize: 11, color: _kAccent, fontWeight: FontWeight.w500)),
                              ),
                            ))
                            .toList(),
                      ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: _kDivider),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _launchUrl('https://${TenantSession.host}/privacy-policy'),
                      child: Text(
                        'Política de privacidad',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], decoration: TextDecoration.underline, decorationColor: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ─── Nav chip ─────────────────────────────────────────────────────────────────

class _NavChip extends StatelessWidget {
  final CatalogNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavChip({required this.item, required this.isSelected, required this.onTap});

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
                color: isSelected ? _kAccent.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? _kAccent : _kDivider, width: isSelected ? 2 : 1),
              ),
              child: item.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(imageUrl: item.imageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _icon()),
                    )
                  : _icon(),
            ),
            const SizedBox(height: 4),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _kAccent : _kSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon() => Icon(item.id < 0 ? Icons.home_rounded : Icons.category_outlined, size: 22, color: isSelected ? _kAccent : _kSub);
}

// ─── Featured card ────────────────────────────────────────────────────────────

class _FeaturedCard extends StatefulWidget {
  final CatalogProduct product;
  final VoidCallback onTap;
  const _FeaturedCard({required this.product, required this.onTap});
  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  final _wishlist = WishlistNotifier.instance;

  Future<void> _addToCart(BuildContext context) async {
    final p = widget.product;
    final attrs = p.availableAttrs;
    String? variantLabel;
    double? variantPrice;
    int? variantStock;
    int? variantManageStock;
    int? variantCombinationId;

    if (attrs.isEmpty) {
      // no variants — use base price
    } else {
      // Fetch variant prices from API before showing picker
      List<ProductVariant> variants = [];
      if (p.id != 0) {
        final res = await MitaiApiService().getProductVariants(p.id);
        if (res is Success<List<ProductVariant>>) variants = res.data;
      }

      if (attrs.length == 1 && variants.isEmpty) {
        variantLabel = attrs.first;
      } else {
        variantLabel = await _showCartVariantSheet(context, p.attrGroups, attrs.first);
        if (variantLabel == null) return;
      }

      // Look up variant price, stock and combination id
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(variantLabel != null
            ? '${p.name} ($variantLabel) agregado al carrito'
            : '${p.name} agregado al carrito'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(label: 'Ver carrito', onPressed: () {
          Navigator.pushNamed(context, 'client/shopping_bag');
        }),
      ),
    );
  }

  Future<void> _toggleWishlist() async {
    final p = widget.product;
    if (_wishlist.contains(p.id)) { await _wishlist.remove(p.id); return; }
    final attrs = p.availableAttrs;
    if (attrs.isEmpty) {
      await _wishlist.add(WishlistItem(product: p));
    } else if (attrs.length == 1) {
      await _wishlist.add(WishlistItem(product: p, variantLabel: attrs.first));
    } else {
      final picked = await _showVariantPicker(context, attrs);
      if (picked == null) return;
      await _wishlist.add(WishlistItem(product: p, variantLabel: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final attrs = p.availableAttrs;
    return ListenableBuilder(
      listenable: _wishlist,
      builder: (context, _) {
        final inWishlist = _wishlist.contains(p.id);
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
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: p.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: p.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                memCacheWidth: 400,
                                memCacheHeight: 400,
                                placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5)),
                                errorWidget: (_, __, ___) => _imgPlaceholder(),
                              )
                            : _imgPlaceholder(),
                      ),
                      if (p.hasDiscount)
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(6)),
                            child: Text('-${p.discount}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      Positioned(
                        top: 6, right: 6,
                        child: GestureDetector(
                          onTap: _toggleWishlist,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)]),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Icon(inWishlist ? Icons.favorite : Icons.favorite_border, key: ValueKey(inWishlist), size: 16, color: inWishlist ? const Color(0xFFE53935) : _kSub),
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
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                      const SizedBox(height: 4),
                      if (p.hasDiscount) ...[
                        Text('₡${fmtPrice(p.price)}', style: const TextStyle(fontSize: 10, color: _kSub, decoration: TextDecoration.lineThrough)),
                        Text('₡${fmtPrice(p.finalPrice)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE53935))),
                      ] else
                        Text('₡${fmtPrice(p.price)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _addToCart(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_shopping_cart, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Agregar', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
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
      },
    );
  }

  Widget _imgPlaceholder() => Container(
    color: const Color(0xFFF5F5F5),
    child: const Center(child: Icon(Icons.image_outlined, size: 36, color: Color(0xFFBDBDBD))),
  );
}

// ─── Contact chip (footer) ────────────────────────────────────────────────────

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.25))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}

// ─── Variant pickers ──────────────────────────────────────────────────────────

Future<String?> _showCartVariantSheet(BuildContext context, Map<String, List<String>> attrGroups, String defaultVariant) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _CartVariantPickerSheet(attrGroups: attrGroups, defaultVariant: defaultVariant),
  );
}

class _CartVariantPickerSheet extends StatefulWidget {
  final Map<String, List<String>> attrGroups;
  final String defaultVariant;
  const _CartVariantPickerSheet({required this.attrGroups, required this.defaultVariant});
  @override
  State<_CartVariantPickerSheet> createState() => _CartVariantPickerSheetState();
}

class _CartVariantPickerSheetState extends State<_CartVariantPickerSheet> {
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.attrGroups.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSub)),
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
                                color: isSel ? _kAccent : const Color(0xFFF5F0EB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _kAccent.withOpacity(isSel ? 1.0 : 0.3)),
                              ),
                              child: Text(v, style: TextStyle(
                                  fontSize: 13, color: isSel ? Colors.white : _kAccent, fontWeight: FontWeight.w600)),
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
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('Agregar al carrito', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _showVariantPicker(BuildContext context, List<String> attrs) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _VariantPickerSheet(attrs: attrs),
  );
}

Future<String?> _showSelectableAttrsSheet(BuildContext context, Map<String, List<String>> attrGroups) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _SelectableAttrsSheet(attrGroups: attrGroups),
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
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Atributos disponibles', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
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
                      Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSub)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: e.value.map((v) {
                          final isSel = _selected[e.key] == v;
                          return GestureDetector(
                            onTap: () => setState(() { if (isSel) _selected.remove(e.key); else _selected[e.key] = v; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: isSel ? _kAccent : const Color(0xFFF5F0EB), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kAccent.withOpacity(isSel ? 1.0 : 0.3))),
                              child: Text(v, style: TextStyle(fontSize: 13, color: isSel ? Colors.white : _kAccent, fontWeight: FontWeight.w600)),
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
              style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.favorite, size: 16),
              label: const Text('Guardar en favoritos', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantPickerSheet extends StatelessWidget {
  final List<String> attrs;
  const _VariantPickerSheet({required this.attrs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Seleccioná una variante', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: attrs.map((a) => GestureDetector(
                  onTap: () => Navigator.pop(context, a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFF5F0EB), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kAccent.withOpacity(0.3))),
                    child: Text(a, style: const TextStyle(fontSize: 13, color: _kAccent, fontWeight: FontWeight.w600)),
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

// ─── Loading / error ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _kAccent),
          SizedBox(height: 16),
          Text('Cargando...', style: TextStyle(color: _kSub, fontSize: 13)),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: _kSub),
            const SizedBox(height: 16),
            const Text('No se pudo cargar el catálogo',
                style: TextStyle(fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 12, color: _kSub), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                await TenantSession.clear();
                if (context.mounted) Navigator.pushReplacementNamed(context, 'tenant/select');
              },
              icon: const Icon(Icons.swap_horiz_outlined, size: 16, color: _kSub),
              label: const Text('Cambiar tienda', style: TextStyle(color: _kSub, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
