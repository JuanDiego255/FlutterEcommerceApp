import 'package:app_links/app_links.dart';
import 'package:ecommerce_flutter/injection.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/CartNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/TenantSession.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/WishlistNotifier.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/TenantDirectoryService.dart';
import 'package:ecommerce_flutter/src/domain/models/TenantConfig.dart';
import 'package:ecommerce_flutter/src/blocProviders.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/create/AdminCategoryCreatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/category/update/AdminCategoryUpdatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/home/AdminHomePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/order/detail/AdminOrderDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/create/AdminProductCreatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/list/AdminProductListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/admin/product/update/AdminProductUpdatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/login/LoginPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/barber/agenda/BarberAgendaPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/barber/booking/BarberBookingPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/barber/bookings/MyBookingsPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/barber/home/BarberHomePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/register/RegisterPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/detail/CatalogProductDetailPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/home/CatalogHomePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/products/CatalogProductListPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/auth/token/AdminTokenPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/catalog/tenant/TenantSelectPage.dart';
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
import 'package:ecommerce_flutter/src/presentation/pages/checkout/GuestCheckoutPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/legal/LegalPage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/profile/update/ProfileUpdatePage.dart';
import 'package:ecommerce_flutter/src/presentation/pages/roles/RolesPage.dart';
import 'package:ecommerce_flutter/src/presentation/theme/app_theme.dart';
import 'package:ecommerce_flutter/src/presentation/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  // Nombres de días/meses en español para DateFormat(..., 'es').
  await initializeDateFormatting('es');
  await TenantSession.initialize();
  await SecureStorageService.initializeCache();
  await WishlistNotifier.instance.reload();
  ThemeController.syncFromSession();
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
      if (uri == null) return;
      if (uri.toString().contains('/success')) {
        navigatorKey.currentState?.pushNamed('client/home');
        return;
      }
      // QR del local: myapp://tenant/{id} — abre directo esa tienda
      // (feature premium qr_deeplink del tenant destino).
      if (uri.scheme == 'myapp' &&
          uri.host == 'tenant' &&
          uri.pathSegments.isNotEmpty) {
        _openTenantFromLink(uri.pathSegments.first);
      }
    });
  }

  Future<void> _openTenantFromLink(String tenantId) async {
    try {
      final tenants = await TenantDirectoryService().fetch();
      final matches = tenants.where((t) => t.id == tenantId).toList();
      if (matches.isEmpty) return;
      final t = matches.first;
      if (!t.features.contains('qr_deeplink')) return;

      final changed =
          TenantSession.isConfigured && TenantSession.host != t.domain;
      if (changed) {
        await SecureStorageService.clearAll();
      }
      await TenantSession.save(TenantConfig(
        domain: t.domain,
        type: t.type,
        colorHex: t.colorHex,
        features: t.features,
      ));
      // El QR del local deja la tienda como predeterminada.
      await TenantSession.setDefaultEnabled(true);
      CartNotifier.instance.update(0);
      await WishlistNotifier.instance.reload();
      ThemeController.syncFromSession();

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
          TenantSession.homeRoute, (route) => false);
    } catch (_) {
      // enlace inválido o sin red: se ignora silenciosamente
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: ValueListenableBuilder<Color?>(
        valueListenable: ThemeController.accent,
        builder: (context, accent, child) => MaterialApp(
        builder: FToastBuilder(),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'SafeWor Solutions',
        // Acento de marca del tenant (feature premium 'branding') o el
        // dorado Oscuro Premium por defecto.
        theme: AppTheme.dark(accent: accent),
        // El selector solo se salta si el usuario marcó la tienda como
        // predeterminada; el home depende de la vertical (ecommerce/barbería).
        initialRoute: (TenantSession.isConfigured && TenantSession.defaultEnabled)
            ? TenantSession.homeRoute
            : 'tenant/select',
        routes: {
          'tenant/select': (BuildContext context) => const TenantSelectPage(),
          'admin/token': (BuildContext context) => const AdminTokenPage(),
          'login': (BuildContext context) => LoginPage(),
          'register': (BuildContext context) => RegisterPage(),
          'catalog/home': (BuildContext context) => const CatalogHomePage(),
          'barber/home': (BuildContext context) => const BarberHomePage(),
          'barber/booking': (BuildContext context) => const BarberBookingPage(),
          'barber/my-bookings': (BuildContext context) => const MyBookingsPage(),
          'barber/agenda': (BuildContext context) => const BarberAgendaPage(),
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
          'checkout/guest': (BuildContext context) => const GuestCheckoutPage(),
          'legal': (BuildContext context) => const LegalPage(),
        },
        ),
      ),
    );
  }
}
