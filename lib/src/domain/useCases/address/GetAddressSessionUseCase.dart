import 'package:ecommerce_flutter/src/domain/repository/AddressRepository.dart';

class GetAddressSessionUseCase {
  AddressRepository addressRepository;

  GetAddressSessionUseCase(this.addressRepository);

  run() => addressRepository.getAddressSession();
}