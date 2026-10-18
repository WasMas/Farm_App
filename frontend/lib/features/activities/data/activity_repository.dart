import 'package:dio/dio.dart';

import '../../../core/collection_api.dart';
import '../domain/activity.dart';

class ActivityRepository {
  ActivityRepository(this.dio);
  final Dio dio;
  Future<List<ActivityRecord>> list({String? kind, int? cycle}) async =>
      (await fetchCollection(
        dio,
        'activities/',
        query: {
          'kind': ?kind,
          'cycle': ?cycle,
        },
      )).map(ActivityRecord.fromJson).toList();
  Future<ActivityRecord> save(Map<String, dynamic> data, [int? id]) async =>
      ActivityRecord.fromJson(
        (id == null
                ? await dio.post('activities/', data: data)
                : await dio.patch('activities/$id/', data: data))
            .data,
      );
  Future<void> delete(int id) => dio.delete('activities/$id/');
}
