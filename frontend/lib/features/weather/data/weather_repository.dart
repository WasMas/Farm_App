import 'package:dio/dio.dart';

import '../domain/weather_report.dart';

class WeatherRepository {
  WeatherRepository(this.dio);
  final Dio dio;
  Future<WeatherConfig> config() async =>
      WeatherConfig.fromJson((await dio.get('weather/config/')).data);
  Future<WeatherConfig> configure({
    required bool enabled,
    required String mode,
    String key = '',
    bool clearKey = false,
  }) async => WeatherConfig.fromJson(
    (await dio.patch(
      'weather/config/',
      data: {
        'enabled': enabled,
        'mode': mode,
        'api_key': key,
        'clear_key': clearKey,
      },
    )).data,
  );
  Future<WeatherReport> weather(int farm, {bool refresh = false}) async =>
      WeatherReport.fromJson(
        (await dio.get(
          'weather/',
          queryParameters: {'farm': farm, 'refresh': refresh},
        )).data,
      );
}
