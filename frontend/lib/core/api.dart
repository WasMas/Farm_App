import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_store.dart';
import 'data_revision.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/',
);
final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(
    ref.watch(tokenStoreProvider),
    onExpired: () => ref.read(sessionExpiredProvider).add(null),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        if (![
              'GET',
              'HEAD',
              'OPTIONS',
            ].contains(response.requestOptions.method) &&
            !response.requestOptions.path.startsWith('auth/')) {
          ref.read(dataRevisionProvider.notifier).changed();
        }
        handler.next(response);
      },
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

Dio createDio(
  TokenStore store, {
  String baseUrl = apiBaseUrl,
  void Function()? onExpired,
}) {
  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  );
  final dio = Dio(options);
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await store.read('access');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        if (error.response?.statusCode != 401 ||
            [
              'auth/login/',
              'auth/register/',
              'auth/refresh/',
            ].contains(request.path) ||
            request.extra['retried'] == true) {
          handler.next(error);
          return;
        }
        try {
          final refresh = await store.read('refresh');
          if (refresh == null) throw StateError('No session');
          var access = await store.read('access');
          if (request.headers['Authorization'] == 'Bearer $access') {
            final response = await Dio(options)
                .post('auth/refresh/', data: {'refresh': refresh});
            access = response.data['access'] as String;
            await store.write('access', access);
            await store.write('refresh', response.data['refresh'] as String);
          }
          request.headers['Authorization'] = 'Bearer $access';
          request.extra['retried'] = true;
          handler.resolve(await dio.fetch(request));
        } catch (refreshError) {
          if (refreshError is! DioException ||
              refreshError.response?.statusCode == 401) {
            await store.clear();
            onExpired?.call();
          }
          handler.next(error);
        }
      },
    ),
  );
  return dio;
}

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
