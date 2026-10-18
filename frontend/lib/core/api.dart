import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/',
);
final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  ),
);

String apiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      return data.entries
          .map(
            (e) =>
                '${e.key == 'detail' ? '' : '${e.key}: '}${e.value is List ? (e.value as List).join(', ') : e.value}',
          )
          .join('\n');
    }
    return 'Could not reach Fieldbook. Check your connection and server address.';
  }
  return 'Something went wrong. Please try again.';
}
