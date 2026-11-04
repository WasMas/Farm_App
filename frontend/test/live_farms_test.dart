import 'package:dio/dio.dart';
import 'package:fieldbook/core/api.dart';
import 'package:fieldbook/features/auth/data/auth_repository.dart';
import 'package:fieldbook/features/farms/data/farm_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  test('Flutter farm/field CRUD, validation, sharing and isolation', () async {
    final tokens = MemoryTokens(), otherTokens = MemoryTokens();
    final dio = createDio(tokens), otherDio = createDio(otherTokens);
    final auth = AuthRepository(dio, tokens),
        otherAuth = AuthRepository(otherDio, otherTokens);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await auth.register(
      'owner_$stamp',
      'Owner',
      'owner_$stamp@example.com',
      'Fixture-passphrase-802!',
    );
    await otherAuth.register(
      'other_$stamp',
      'Other',
      'other_$stamp@example.com',
      'Fixture-passphrase-802!',
    );
    final repo = FarmRepository(dio), other = FarmRepository(otherDio);
    var farm = await repo.saveFarm({
      'name': 'Olive grove',
      'location': 'Tunis',
      'total_area': '10.50',
      'latitude': '36.8',
      'longitude': '10.18',
    });
    expect((await repo.farms()).single.id, farm.id);
    expect(await other.farms(), isEmpty);
    await expectLater(
      other.farm(farm.id),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          404,
        ),
      ),
    );
    var field = await repo.saveField({
      'farm': farm.id,
      'name': 'North',
      'area': '2.25',
      'soil_type': 'loam',
    });
    expect((await repo.fields(farm.id)).single.area, 2.25);
    field = await repo.saveField({'area': '3.10'}, field.id);
    expect(field.area, 3.1);
    await expectLater(
      repo.saveField({
        'farm': farm.id,
        'name': 'Too big',
        'area': '20',
        'soil_type': 'clay',
      }),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          400,
        ),
      ),
    );
    farm = await repo.saveFarm({'name': 'Edited grove'}, farm.id);
    expect(farm.name, 'Edited grove');
    await repo.share(farm.id, 'other_$stamp', 'viewer');
    expect((await other.farms()).single.canEdit, isFalse);
    await expectLater(
      other.saveFarm({'name': 'Forbidden'}, farm.id),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          403,
        ),
      ),
    );
    await repo.deleteField(field.id);
    expect(await repo.fields(farm.id), isEmpty);
    await repo.deleteFarm(farm.id);
    expect(await repo.farms(), isEmpty);
    await auth.logout();
    await otherAuth.logout();
  }, skip: !const bool.fromEnvironment('RUN_LIVE_API_TESTS'));
}
