// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:ecommerce_flutter/src/data/dataSource/local/SharedPref.dart'
    as _i838;
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/AddressService.dart'
    as _i993;
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/AuthService.dart'
    as _i543;
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CategoriesService.dart'
    as _i485;
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MercadoPagoService.dart'
    as _i282;
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/OrdersService.dart'
    as _i1017;
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/ProductsService.dart'
    as _i700;
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/UsersService.dart'
    as _i226;
import 'package:ecommerce_flutter/src/di/AppModule.dart' as _i987;
import 'package:ecommerce_flutter/src/domain/repository/AddressRepository.dart'
    as _i879;
import 'package:ecommerce_flutter/src/domain/repository/AuthRepository.dart'
    as _i148;
import 'package:ecommerce_flutter/src/domain/repository/CategoriesRepository.dart'
    as _i179;
import 'package:ecommerce_flutter/src/domain/repository/MercadoPagoRepository.dart'
    as _i1023;
import 'package:ecommerce_flutter/src/domain/repository/OrdersRepository.dart'
    as _i621;
import 'package:ecommerce_flutter/src/domain/repository/ProductsRepository.dart'
    as _i994;
import 'package:ecommerce_flutter/src/domain/repository/ShoppingBagRepository.dart'
    as _i747;
import 'package:ecommerce_flutter/src/domain/repository/UsersRepository.dart'
    as _i808;
import 'package:ecommerce_flutter/src/domain/useCases/address/AddressUseCases.dart'
    as _i265;
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart'
    as _i322;
import 'package:ecommerce_flutter/src/domain/useCases/categories/CategoriesUseCases.dart'
    as _i578;
import 'package:ecommerce_flutter/src/domain/useCases/MercadoPago/MercadoPagoUseCases.dart'
    as _i410;
import 'package:ecommerce_flutter/src/domain/useCases/orders/OrdersUseCases.dart'
    as _i572;
import 'package:ecommerce_flutter/src/domain/useCases/products/ProductsUseCases.dart'
    as _i516;
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart'
    as _i356;
import 'package:ecommerce_flutter/src/domain/useCases/users/UsersUseCases.dart'
    as _i525;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.factory<_i838.SharedPref>(() => appModule.sharedPref);
    gh.factory<_i543.AuthService>(() => appModule.authService);
    gh.factory<_i226.UsersService>(() => appModule.usersService);
    gh.factory<_i485.CategoriesService>(() => appModule.categoriesService);
    gh.factory<_i700.ProductsService>(() => appModule.productsService);
    gh.factory<_i282.MercadoPagoService>(() => appModule.mercadoPagoService);
    gh.factory<_i993.AddressService>(() => appModule.addressService);
    gh.factory<_i1017.OrdersService>(() => appModule.ordersService);
    gh.factory<_i148.AuthRepository>(() => appModule.authRepository);
    gh.factory<_i808.UsersRepository>(() => appModule.usersRepository);
    gh.factory<_i1023.MercadoPagoRepository>(
      () => appModule.mercadoPagoRepository,
    );
    gh.factory<_i179.CategoriesRepository>(
      () => appModule.categoriesRepository,
    );
    gh.factory<_i994.ProductsRepository>(() => appModule.productsRepository);
    gh.factory<_i747.ShoppingBagRepository>(
      () => appModule.shoppingBagRepository,
    );
    gh.factory<_i879.AddressRepository>(() => appModule.addressRepository);
    gh.factory<_i621.OrdersRepository>(() => appModule.ordersRepository);
    gh.factory<_i322.AuthUseCases>(() => appModule.authUseCases);
    gh.factory<_i525.UsersUseCases>(() => appModule.usersUseCases);
    gh.factory<_i578.CategoriesUseCases>(() => appModule.categoriesUseCases);
    gh.factory<_i516.ProductsUseCases>(() => appModule.productsUseCases);
    gh.factory<_i356.ShoppingBagUseCases>(() => appModule.shoppingBagUseCases);
    gh.factory<_i265.AddressUseCases>(() => appModule.addressUseCases);
    gh.factory<_i410.MercadoPagoUseCases>(() => appModule.mercadoPagoUseCases);
    gh.factory<_i572.OrdersUseCases>(() => appModule.ordersUseCases);
    return this;
  }
}

class _$AppModule extends _i987.AppModule {}
