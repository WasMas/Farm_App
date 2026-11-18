import 'package:dio/dio.dart';

class AdminRepository {
  AdminRepository(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> dashboard() async => Map<String, dynamic>.from(
    (await dio.get('admin/dashboard/')).data as Map,
  );

  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? role,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (role != null) data['role'] = role;
    if (isActive != null) data['is_active'] = isActive;

    final response = await dio.patch('admin/users/$userId/', data: data);

    return Map<String, dynamic>.from(response.data as Map);
  }
}
