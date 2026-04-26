import 'package:ecommerce_flutter/src/data/dataSource/local/SecureStorageService.dart';
import 'package:ecommerce_flutter/src/data/dataSource/local/SharedPref.dart';
import 'package:ecommerce_flutter/src/data/dataSource/remote/services/AuthService.dart';
import 'package:ecommerce_flutter/src/domain/models/AuthResponse.dart';
import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:ecommerce_flutter/src/domain/repository/AuthRepository.dart';
import 'package:ecommerce_flutter/src/domain/utils/Resource.dart';

class AuthRepositoryImpl implements AuthRepository {

  AuthService authService;
  SharedPref sharedPref;

  AuthRepositoryImpl(this.authService, this.sharedPref);

  @override
  Future<Resource<AuthResponse>> login(String email, String password) {
    return authService.login(email, password);
  }

  @override
  Future<Resource<AuthResponse>> register(User user) {
    return authService.register(user);
  }

  @override
  Future<AuthResponse?> getUserSession() async {
    final data = await sharedPref.read('user');
    if (data == null) return null;

    // Legacy migration: token was stored inside the 'user' JSON map.
    final legacyToken = data['token'] as String?;
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await SecureStorageService.saveAuthToken(legacyToken);
      final cleaned = Map<String, dynamic>.from(data as Map)..remove('token');
      await sharedPref.save('user', cleaned);
    }

    final token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) return null;

    return AuthResponse(
      user: User.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
      token: token,
    );
  }

  @override
  Future<void> saveUserSession(AuthResponse authResponse) async {
    await SecureStorageService.saveAuthToken(authResponse.token);
    await sharedPref.save('user', {'user': authResponse.user.toJson()});
  }

  @override
  Future<bool> logout() async {
    await SecureStorageService.clearAuthToken();
    return sharedPref.remove('user');
  }

}