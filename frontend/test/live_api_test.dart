import 'package:dio/dio.dart';
import 'package:fieldbook/core/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const live = bool.fromEnvironment('RUN_LIVE_API_TESTS');
  test('Flutter Dio reaches Django and PostgreSQL', () async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    final response = await dio.get('health/');
    expect(response.data['status'], 'ok');
    expect(response.data['database'], 'postgresql');
  }, skip: !live);
}
