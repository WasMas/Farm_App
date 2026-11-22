import 'package:dio/dio.dart';

import '../domain/farm_summary.dart';

class DashboardRepository {
  DashboardRepository(this.dio);
  final Dio dio;
  Future<FarmSummary> overview([int? farm]) async => FarmSummary.fromJson(
    (await dio.get(
      'dashboard/',
      queryParameters: farm == null ? null : {'farm': farm},
    )).data,
  );
}
