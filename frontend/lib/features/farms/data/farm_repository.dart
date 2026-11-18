import 'package:dio/dio.dart';

import '../../../core/collection_api.dart';
import '../domain/farm.dart';

class FarmRepository {
  FarmRepository(this.dio);
  final Dio dio;
  Future<List<Farm>> farms() async =>
      (await fetchCollection(dio, 'farms/')).map(Farm.fromJson).toList();
  Future<Farm> farm(int id) async =>
      Farm.fromJson((await dio.get('farms/$id/')).data);
  Future<List<FarmField>> fields([int? farm]) async => (await fetchCollection(
    dio,
    'fields/',
    query: farm == null ? null : {'farm': farm},
  )).map(FarmField.fromJson).toList();
  Future<Farm> saveFarm(Map<String, dynamic> data, [int? id]) async =>
      Farm.fromJson(
        (id == null
                ? await dio.post('farms/', data: data)
                : await dio.patch('farms/$id/', data: data))
            .data,
      );
  Future<void> deleteFarm(int id) => dio.delete('farms/$id/');
  Future<FarmField> saveField(Map<String, dynamic> data, [int? id]) async =>
      FarmField.fromJson(
        (id == null
                ? await dio.post('fields/', data: data)
                : await dio.patch('fields/$id/', data: data))
            .data,
      );
  Future<void> deleteField(int id) => dio.delete('fields/$id/');
  Future<List<Map<String, dynamic>>> members(int id) async =>
      ((await dio.get('farms/$id/members/')).data as List)
          .cast<Map<String, dynamic>>();
  Future<void> share(int id, String username, String role) => dio.post(
    'farms/$id/members/',
    data: {'username': username, 'role': role},
  );
  Future<void> unshare(int id, int user) =>
      dio.delete('farms/$id/members/$user/');
  Future<void> createWorker(int id, Map<String, dynamic> data) =>
      dio.post('farms/$id/workers/', data: data);
  Future<void> assignWorker(int id, {required int field, required int worker}) =>
      dio.post(
        'farms/$id/assignments/',
        data: {'field': field, 'worker': worker},
      );
}
