import 'package:dio/dio.dart';

Future<List<Map<String, dynamic>>> fetchCollection(
  Dio dio,
  String path, {
  Map<String, dynamic>? query,
}) async {
  final result = <Map<String, dynamic>>[];
  String? next = path;
  while (next != null) {
    final response = await dio.get(
      next,
      queryParameters: next == path ? query : null,
    );
    final data = response.data;
    if (data is List) {
      result.addAll(data.cast<Map<String, dynamic>>());
      break;
    }
    result.addAll((data['results'] as List).cast<Map<String, dynamic>>());
    next = data['next'] as String?;
  }
  return result;
}
