import 'dart:io';

import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

abstract class UsersRepository {

  Future<Resource<User>> update(int id, User user, File? image);

}