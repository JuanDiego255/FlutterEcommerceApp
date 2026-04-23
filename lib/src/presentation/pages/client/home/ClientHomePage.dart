import 'package:ecommerce_flutter/main.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/category/list/ClientCategoryListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeBloc.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeEvent.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/bloc/ClientHomeState.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/list/ClientOrderListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/profile/info/ProfileInfoPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/RolesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {

  ClientHomeBloc? _bloc;

  List<Widget> pageList = <Widget>[
    ClientCategoryListPage(),
    ClientOrderListPage(),
    ProfileInfoPage(),
    RolesPage()
  ]; 

  @override
  Widget build(BuildContext context) {
    _bloc = BlocProvider.of<ClientHomeBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'client/shopping_bag');
            }, 
            icon: Icon(
              Icons.shopping_bag,
              color: Colors.black,         
            )
          )
        ],
      ),
      drawer: BlocBuilder<ClientHomeBloc, ClientHomeState>(
        builder: (context, state) {
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black
                  ),
                  child: Text(
                    'Menu de Cliente',
                    style: TextStyle(
                      color: Colors.white
                    ),
                  )
                ),
                ListTile(
                  title: Text('Categorias'),
                  selected: state.pageIndex == 0,
                  onTap: () {
                    _bloc?.add(ChangeDrawerPage(pageIndex: 0));
                    Navigator.pop(context);
                  },
                ),
                 ListTile(
                  title: Text('Mis pedidos'),
                  selected: state.pageIndex == 1,
                  onTap: () {
                    _bloc?.add(ChangeDrawerPage(pageIndex: 1));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('Perfil de usuario'),
                  selected: state.pageIndex == 2,
                  onTap: () {
                    _bloc?.add(ChangeDrawerPage(pageIndex: 2));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('Roles'),
                  selected: state.pageIndex == 3,
                  onTap: () {
                    _bloc?.add(ChangeDrawerPage(pageIndex: 3));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('Cerrar sesion'),
                  onTap: () {
                    _bloc?.add(Logout());
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => MyApp()), 
                      (route) => false
                    );
                  },
                ),
              ],
            ),
          );
        }
      ),
      body: BlocBuilder<ClientHomeBloc, ClientHomeState>(
        builder: (context, state) {
          return pageList[state.pageIndex];
        }
      )
    );
  }
}