import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/session_store.dart';
import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository(this.dio, this.store);

  final Dio dio;
  final TokenStore store;

  Future<AppUser?> restore() async {
    if (await store.read('refresh') == null) return null;

    try {
      final response = await dio.get('auth/me/');
      return AppUser.fromJson(Map<String, dynamic>.from(response.data));
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

    return AppUser.fromJson(Map<String, dynamic>.from(response.data['user']));
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

  Future<AppUser> updateProfile({
    required String name,
    required String bio,
    required String profileImageUrl,
    XFile? image,
    bool clearUploadedImage = false,
  }) async {
    late final Response response;

    if (image != null) {
      final imageBytes = await image.readAsBytes();

      final formData = FormData.fromMap({
        'name': name,
        'bio': bio,
        'profile_image_url': '',
        'profile_image': MultipartFile.fromBytes(
          imageBytes,
          filename: image.name,
        ),
      });

      response = await dio.patch('auth/me/', data: formData);
    } else {
      final data = <String, dynamic>{
        'name': name,
        'bio': bio,
        'profile_image_url': profileImageUrl.trim(),
      };

      if (profileImageUrl.trim().isNotEmpty || clearUploadedImage) {
        data['profile_image'] = null;
      }

      response = await dio.patch('auth/me/', data: data);
    }

    return AppUser.fromJson(Map<String, dynamic>.from(response.data));
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
