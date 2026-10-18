import 'package:fieldbook/core/api.dart';
import 'package:fieldbook/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  test('Flutter registration, login, restoration, and logout reach Django/PostgreSQL', () async {
    final store = MemoryTokens();
    final dio = createDio(store);
    final repo = AuthRepository(dio, store);
    final name = 'e2e_${DateTime.now().microsecondsSinceEpoch}';
    const password = 'A-fixture-passphrase-481!';
    final user = await repo.register(
      name,
      'Test Farmer',
      '$name@example.com',
      password,
    );
    expect(user.role, 'farmer');
    expect(user.isAdmin, isFalse);
    expect((await repo.restore())?.id, user.id);
    // A rejected access token must be refreshed transparently.
    await store.write('access', 'expired-token');
    expect((await dio.get('auth/me/')).data['id'], user.id);
    await repo.logout();
    expect(await repo.restore(), isNull);
    expect((await repo.login(name, password)).id, user.id);
    await repo.logout();
  }, skip: !const bool.fromEnvironment('RUN_LIVE_API_TESTS'));
}
