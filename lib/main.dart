import 'package:app_links/app_links.dart';
import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/blocProviders.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/create/AdminCategoryCreatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/update/AdminCategoryUpdatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/home/AdminHomePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/AdminOrderDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/create/AdminProductCreatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/list/AdminProductListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/update/AdminProductUpdatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/LoginPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/register/RegisterPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/detail/CatalogProductDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/CatalogHomePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/CatalogProductListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/wishlist/WishlistPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/ShoppingBag/ClientShoppingBagPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/create/ClientAddressCreatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/address/list/ClientAddressListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/home/ClientHomePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/order/detail/ClientOrderDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/form/ClientPaymentFormPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/installments/ClientPaymentInstallmentsPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/payment/status/ClientPaymentStatusPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/product/detail/ClientProductDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/client/product/list/ClientProductListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/profile/info/ProfileInfoPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/profile/update/ProfileUpdatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/RolesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await TenantSession.initialize(); // Load saved tenant config before any API call
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _listenToLinks();
  }

  void _listenToLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.toString().contains('/success')) {
        navigatorKey.currentState?.pushNamed('client/home');
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: MaterialApp(
        builder: FToastBuilder(),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: TenantSession.isConfigured ? 'catalog/home' : 'login',
        routes: {
          'login': (BuildContext context) => LoginPage(),
          'register': (BuildContext context) => RegisterPage(),
          'catalog/home': (BuildContext context) => const CatalogHomePage(),
          'catalog/products': (BuildContext context) => const CatalogProductListPage(),
          'catalog/product/detail': (BuildContext context) => const CatalogProductDetailPage(),
          'catalog/wishlist': (BuildContext context) => const WishlistPage(),
          'roles': (BuildContext context) => RolesPage(),
          'profile/info': (BuildContext context) => ProfileInfoPage(),
          'profile/update': (BuildContext context) => ProfileUpdatePage(),
          'client/home': (BuildContext context) => ClientHomePage(),
          'admin/home': (BuildContext context) => AdminHomePage(),
          'admin/category/create': (BuildContext context) => AdminCategoryCreatePage(),
          'admin/category/update': (BuildContext context) => AdminCategoryUpdatePage(),
          'admin/product/list': (BuildContext context) => AdminProductListPage(),
          'admin/product/create': (BuildContext context) => AdminProductCreatePage(),
          'admin/product/update': (BuildContext context) => AdminProductUpdatePage(),
          'client/product/list': (BuildContext context) => ClientProductListPage(),
          'client/product/detail': (BuildContext context) => ClientProductDetailPage(),
          'client/shopping_bag': (BuildContext context) => ClientShoppingBagPage(),
          'client/address/list': (BuildContext context) => ClientAddressListPage(),
          'client/address/create': (BuildContext context) => ClientAddressCreatePage(),
          'client/payment/form': (BuildContext context) => ClientPaymentFormPage(),
          'client/payment/installments': (BuildContext context) => ClientPaymentInstallmentsPage(),
          'client/payment/status': (BuildContext context) => ClientPaymentStatusPage(),          
          'admin/order/detail': (BuildContext context) => AdminOrderDetailPage(),          
          'client/order/detail': (BuildContext context) => ClientOrderDetailPage(),          
        },
      ),
    );
  }
}
