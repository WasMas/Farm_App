import 'package:dio/dio.dart';

import '../../../core/session_store.dart';
import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository(this.dio, this.store);
  final Dio dio;
  final TokenStore store;

  Future<AppUser?> restore() async {
    if (await store.read('refresh') == null) return null;
    try {
      return AppUser.fromJson((await dio.get('auth/me/')).data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await store.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<AppUser> login(String username, String password) async {
    final response = await dio.post(
      'auth/login/',
      data: {'username': username, 'password': password},
    );
    await store.write('access', response.data['access'] as String);
    await store.write('refresh', response.data['refresh'] as String);
    return AppUser.fromJson(response.data['user']);
  }

  Future<AppUser> register(
    String username,
    String name,
    String email,
    String password,
  ) async {
    await dio.post(
      'auth/register/',
      data: {
        'username': username,
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return login(username, password);
  }

  Future<void> logout() async {
    final refresh = await store.read('refresh');
    try {
      if (refresh != null) {
        await dio.post('auth/logout/', data: {'refresh': refresh});
      }
    } finally {
      await store.clear();
    }
  }
}
