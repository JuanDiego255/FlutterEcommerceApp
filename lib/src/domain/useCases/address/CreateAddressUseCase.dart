import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/repository/AddressRepository.dart';

class CreateAddressUseCase {

  AddressRepository addressRepository;

  CreateAddressUseCase(this.addressRepository);

  run(Address address) => addressRepository.create(address);

}