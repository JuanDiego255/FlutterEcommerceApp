import 'package:ecommerce_flutter/src/data/dataSource/local/SharedPref.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/AddressService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/CategoriesService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/MercadoPagoService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/OrdersService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/ProductsService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/UsersService.dart';
import 'package:ecommerce_flutter/src/data/repository/AddressRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/data/repository/AuthRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/AuthService.dart';
import 'package:ecommerce_flutter/src/data/repository/CategoriesRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/data/repository/MercadoPagoRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/data/repository/OrdersRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/data/repository/ProductsRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/data/repository/ShoppingBagRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/data/repository/UsersRepositoryImpl.dart';
import 'package:ecommerce_flutter/src/domain/repository/AddressRepository.dart';
import 'package:ecommerce_flutter/src/domain/repository/AuthRepository.dart';
import 'package:ecommerce_flutter/src/domain/repository/CategoriesRepository.dart';
import 'package:ecommerce_flutter/src/domain/repository/MercadoPagoRepository.dart';
import 'package:ecommerce_flutter/src/domain/repository/OrdersRepository.dart';
import 'package:ecommerce_flutter/src/domain/repository/ProductsRepository.dart';
import 'package:ecommerce_flutter/src/domain/repository/ShoppingBagRepository.dart';
import 'package:ecommerce_flutter/src/domain/repository/UsersRepository.dart';
import 'package:ecommerce_flutter/src/domain/useCases/MercadoPago/CreateCardTokenUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/MercadoPago/CreatePaymentUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/MercadoPago/GetIdentificationTypesUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/MercadoPago/GetInstallmentsUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/MercadoPago/MercadoPagoUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/AddShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/DeleteItemShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/DeleteShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/GetProductsShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/GetTotalShoppingBagUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/ShoppingBag/ShoppingBagUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/AddressUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/CreateAddressUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/DeleteAddressFromSessionUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/DeleteAddressUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/GetAddressSessionUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/GetUserAddressUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/address/SaveAddressInSessionUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/GetUserSessionUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/LoginUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/LogoutUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/RegisterUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/auth/SaveUserSessionUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/CategoriesUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/CreateCategoryUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/DeleteCategoryUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/GetCategoriesUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/categories/UpdateCategoryUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/CreateOrderUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/GetOrdersByClientUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/GetOrdersUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/OrdersUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/orders/UpdateStatusOrderUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/products/CreateProductUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/products/DeleteProductUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/products/GetProductsByCategoryUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/products/ProductsUseCases.dart';
import 'package:ecommerce_flutter/src/domain/useCases/products/UpdateProductUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/users/UpdateUserUseCase.dart';
import 'package:ecommerce_flutter/src/domain/useCases/users/UsersUseCases.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {

  @injectable
  SharedPref get sharedPref => SharedPref();

  @injectable
  AuthService get authService => AuthService();

  @injectable
  UsersService get usersService => UsersService();

  @injectable
  CategoriesService get categoriesService => CategoriesService();

  @injectable
  ProductsService get productsService => ProductsService();

  @injectable
  MercadoPagoService get mercadoPagoService => MercadoPagoService();

  @injectable
  AddressService get addressService => AddressService();

  @injectable
  OrdersService get ordersService => OrdersService();

  @injectable
  AuthRepository get authRepository => AuthRepositoryImpl(authService, sharedPref);

  @injectable
  UsersRepository get usersRepository => UsersRepositoryImpl(usersService);

  @injectable
  MercadoPagoRepository get mercadoPagoRepository => MercadoPagoRepositoryImpl(mercadoPagoService);

  @injectable
  CategoriesRepository get categoriesRepository => CategoriesRepositoryImpl(categoriesService);

  @injectable
  ProductsRepository get productsRepository => ProductsRepositoryImpl(productsService);

  @injectable
  ShoppingBagRepository get shoppingBagRepository => ShoppingBagRepositoryImpl(sharedPref);

  @injectable
  AddressRepository get addressRepository => AddressRepositoryImpl(addressService, sharedPref);

  @injectable
  OrdersRepository get ordersRepository => OrdersRepositoryImpl(ordersService);

  @injectable
  AuthUseCases get authUseCases => AuthUseCases(
    login: LoginUseCase(authRepository),
    register: RegisterUseCase(authRepository),
    saveUserSession: SaveUserSessionUseCase(authRepository),
    getUserSession: GetUserSessionUseCase(authRepository),
    logout: LogoutUseCase(authRepository)
  );

  @injectable
  UsersUseCases get usersUseCases => UsersUseCases(
    updateUser: UpdateUserUseCase(usersRepository)
  );

  @injectable
  CategoriesUseCases get categoriesUseCases => CategoriesUseCases(
    create: CreateCategoryUseCase(categoriesRepository),
    getCategories: GetCategoriesUseCase(categoriesRepository),
    update: UpdateCategoryUseCase(categoriesRepository),
    delete: DeleteCategoryUseCase(categoriesRepository)
  );

   @injectable
   ProductsUseCases get productsUseCases => ProductsUseCases(
    create: CreateProductUseCase(productsRepository),
    getProductsByCategory: GetProductsByCategoryUseCase(productsRepository),
    update: UpdateProductUseCase(productsRepository),
    delete: DeleteProductUseCase(productsRepository)
  );

  @injectable
  ShoppingBagUseCases get shoppingBagUseCases => ShoppingBagUseCases(
    add: AddShoppingBagUseCase(shoppingBagRepository),
    getProducts: GetProductsShoppingBagUseCase(shoppingBagRepository),
    deleteItem: DeleteItemShoppinBagUseCase(shoppingBagRepository),
    deleteShoppingBag: deleteShoppingBagUseCase(shoppingBagRepository),
    getTotal: GetTotalShoppingBagUseCase(shoppingBagRepository)
  );

  @injectable
  AddressUseCases get addressUseCases => AddressUseCases(
    create: CreateAddressUseCase(addressRepository),
    getUserAddress: GetUserAddressUseCase(addressRepository),
    saveAddressInSession: SaveAddressInSessionUseCase(addressRepository),
    getAddressSession: GetAddressSessionUseCase(addressRepository),
    delete: DeleteAddressUseCase(addressRepository),
    deleteFromSession: DeleteAddressFromSessionUseCase(addressRepository)
  );

  @injectable
  MercadoPagoUseCases get mercadoPagoUseCases => MercadoPagoUseCases(
    getIdentificationTypes: GetIdentificationTypesUseCase(mercadoPagoRepository),
    createCardToken: CreateCardTokenUseCase(mercadoPagoRepository),
    getInstallments: GetInstallmentsUseCase(mercadoPagoRepository),
    createPaymentUseCase: CreatePaymentUseCase(mercadoPagoRepository)
  );

  @injectable
  OrdersUseCases get ordersUseCases => OrdersUseCases(
    getOrders: GetOrdersUseCase(ordersRepository),
    getOrdersByClient: GetOrdersByClientUseCase(ordersRepository),
    updateStatus: UpdateStatusOrderUseCase(ordersRepository),
    createOrder: CreateOrderUseCase(ordersRepository),
  );

}