import 'package:ecommerce_flutter/main.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/catalog/AdminCatalogPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/home/bloc/AdminHomeBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/home/bloc/AdminHomeEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/home/bloc/AdminHomeState.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/orders/AdminOrdersPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/profile/info/ProfileInfoPage.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  AdminHomeBloc? _bloc;

  final List<Widget> _pages = const [
    AdminCatalogPage(),
    AdminOrdersPage(),
    ProfileInfoPage(),
  ];

  final List<String> _titles = ['Catálogo', 'Pedidos', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    _bloc = BlocProvider.of<AdminHomeBloc>(context);

    return BlocBuilder<AdminHomeBloc, AdminHomeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              _titles[state.pageIndex],
              style: TextStyle(
                color: cs.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            actions: [
              if (state.pageIndex == 0)
                IconButton(
                  icon: Icon(Icons.search, color: tokens.textMuted),
                  onPressed: () {},
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: tokens.textMuted),
                color: cs.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                onSelected: (value) {
                  if (value == 'catalog') {
                    Navigator.pushNamedAndRemoveUntil(
                        context, 'catalog/home', (route) => false);
                  } else if (value == 'logout') {
                    _bloc?.add(AdminLogout());
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MyApp()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'catalog',
                    child: Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text('Ver catálogo público',
                            style: TextStyle(color: cs.onBackground)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: cs.error),
                        const SizedBox(width: 8),
                        Text('Cerrar sesión', style: TextStyle(color: cs.error)),
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
              onTap: (i) => _bloc?.add(AdminChangeDrawerPage(pageIndex: i)),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
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
