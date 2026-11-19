import 'package:dio/dio.dart';

class RecommendationRepository {
  RecommendationRepository(this.dio);
  final Dio dio;

  Future<List<Map<String, dynamic>>> list() async {
    final data = (await dio.get('recommendations/')).data;
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> check({DateTime? asOf}) async {
    final data = (await dio.post(
      'recommendations/',
      data: {
        'use_ai': true,
        if (asOf != null) 'as_of': _date(asOf),
      },
    )).data;
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> decide(
    int id,
    bool accept, {
    DateTime? effectiveDate,
  }) async =>
      Map<String, dynamic>.from(
        (await dio.post(
          'recommendations/$id/${accept ? 'accept' : 'refuse'}/',
          data: {
            if (effectiveDate != null) 'as_of': _date(effectiveDate),
          },
        ))
            .data as Map,
      );

  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
}
