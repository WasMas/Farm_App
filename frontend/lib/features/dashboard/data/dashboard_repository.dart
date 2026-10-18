import 'package:dio/dio.dart';

import '../domain/farm_summary.dart';

class DashboardRepository {
  DashboardRepository(this.dio);
  final Dio dio;
  Future<FarmSummary> overview() async =>
      FarmSummary.fromJson((await dio.get('dashboard/')).data);
}
