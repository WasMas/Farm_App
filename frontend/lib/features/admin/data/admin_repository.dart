import 'package:dio/dio.dart';

class AdminRepository {
  AdminRepository(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> dashboard() async => Map<String, dynamic>.from(
    (await dio.get('admin/dashboard/')).data as Map,
  );

  Future<Map<String, dynamic>> createOwner(Map<String, dynamic> data) async =>
      Map<String, dynamic>.from(
        (await dio.post('admin/dashboard/', data: data)).data as Map,
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

  Future<List<Map<String, dynamic>>> audit({
    String? action,
    String? actor,
    String? entity,
    String? start,
    String? end,
  }) async =>
      ((await dio.get(
                'admin/audit/',
                queryParameters: {
                  if (action?.trim().isNotEmpty == true) 'action': action,
                  if (actor?.trim().isNotEmpty == true) 'actor': actor,
                  if (entity?.trim().isNotEmpty == true) 'entity': entity,
                  if (start?.trim().isNotEmpty == true) 'start': start,
                  if (end?.trim().isNotEmpty == true) 'end': end,
                },
              )).data
              as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
}
