import 'package:ecommerce_flutter/main.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/bloc/ClientShoppingBagEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/category/list/ClientCategoryListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeState.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/ClientOrderListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/profile/info/ProfileInfoPage.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  ClientHomeBloc? _bloc;

  static const List<Widget> _pages = [
    ClientCategoryListPage(),
    ClientOrderListPage(),
    ProfileInfoPage(),
  ];

  static const List<String> _titles = ['Catálogo', 'Mis pedidos', 'Mi perfil'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientShoppingBagBloc>().add(GetShoppingBag());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    _bloc = BlocProvider.of<ClientHomeBloc>(context);

    return BlocBuilder<ClientHomeBloc, ClientHomeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              _titles[state.pageIndex],
              style: TextStyle(color: cs.onBackground, fontWeight: FontWeight.w700, fontSize: 20),
            ),
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: CartNotifier.instance,
                builder: (_, count, __) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shopping_bag_outlined, color: cs.onBackground),
                      onPressed: () => Navigator.pushNamed(context, 'client/shopping_bag')
                          .then((_) { context.read<ClientShoppingBagBloc>().add(GetShoppingBag()); }),
                      tooltip: 'Carrito',
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 17, height: 17,
                          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: TextStyle(color: cs.onPrimary, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: tokens.textMuted),
                color: cs.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                onSelected: (value) {
                  if (value == 'logout') {
                    _bloc?.add(Logout());
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MyApp()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: cs.error),
                        const SizedBox(width: 8),
                        Text('Cerrar sesión', style: TextStyle(color: cs.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: IndexedStack(
            index: state.pageIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: cs.background,
              border: Border(top: BorderSide(color: cs.outline)),
            ),
            child: BottomNavigationBar(
              currentIndex: state.pageIndex,
              onTap: (i) => _bloc?.add(ChangeDrawerPage(pageIndex: i)),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.category_outlined),
                  activeIcon: Icon(Icons.category),
                  label: 'Catálogo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Pedidos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
