import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fieldbook/core/api.dart';
import 'package:fieldbook/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  test(
    'A temporary refresh-service failure preserves the saved session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.statusCode = request.uri.path.endsWith('/refresh/')
            ? 503
            : 401;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"detail":"Temporarily unavailable"}');
        await request.response.close();
      });
      final store = MemoryTokens();
      await store.write('access', 'fixture-expired');
      await store.write('refresh', 'fixture-refresh');
      var expired = false;
      final repo = AuthRepository(
        createDio(
          store,
          baseUrl: 'http://127.0.0.1:${server.port}/api/',
          onExpired: () => expired = true,
        ),
        store,
      );
      await expectLater(
        repo.restore(),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            503,
          ),
        ),
      );
      expect(await store.read('refresh'), 'fixture-refresh');
      expect(expired, isFalse);
    },
  );
}
