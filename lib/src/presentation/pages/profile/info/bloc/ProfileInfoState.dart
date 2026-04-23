import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:equatable/equatable.dart';

class ProfileInfoState extends Equatable {

  final User? user;

  const ProfileInfoState({
    this.user
  });
  
  ProfileInfoState copyWith({
    User? user
  }) {
    return ProfileInfoState(
      user: user
    );
  }

  @override
  List<Object?> get props => [user];

}