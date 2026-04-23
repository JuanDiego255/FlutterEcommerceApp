import 'package:ecommerce_flutter/src/domain/models/Address.dart';
import 'package:ecommerce_flutter/src/domain/repository/AddressRepository.dart';

class SaveAddressInSessionUseCase {

  AddressRepository addressRepository;

  SaveAddressInSessionUseCase(this.addressRepository);

  run(Address address) => addressRepository.saveAddressInSession(address);

}