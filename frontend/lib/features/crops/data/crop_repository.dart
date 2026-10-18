import 'package:dio/dio.dart';

import '../../../core/collection_api.dart';
import '../domain/crop_cycle.dart';

class CropRepository {
  CropRepository(this.dio);
  final Dio dio;
  Future<List<CropType>> types() async => (await fetchCollection(
    dio,
    'crop-types/',
  )).map(CropType.fromJson).toList();
  Future<List<CropCycle>> cycles() async => (await fetchCollection(
    dio,
    'crop-cycles/',
  )).map(CropCycle.fromJson).toList();
  Future<CropCycle> save(Map<String, dynamic> data, [int? id]) async =>
      CropCycle.fromJson(
        (id == null
                ? await dio.post('crop-cycles/', data: data)
                : await dio.patch('crop-cycles/$id/', data: data))
            .data,
      );
  Future<void> delete(int id) => dio.delete('crop-cycles/$id/');
  Future<void> saveType(Map<String, dynamic> data, [int? id]) => id == null
      ? dio.post('crop-types/', data: data)
      : dio.patch('crop-types/$id/', data: data);
  Future<void> deleteType(int id) => dio.delete('crop-types/$id/');
}
