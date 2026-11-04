import 'package:dio/dio.dart';
import 'package:fieldbook/core/api.dart';
import 'package:fieldbook/features/auth/data/auth_repository.dart';
import 'package:fieldbook/features/farms/data/farm_repository.dart';
import 'package:fieldbook/features/crops/data/crop_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  test('Flutter planting lifecycle preserves seasons and protects referenced fields', () async {
    final tokens = MemoryTokens();
    final dio = createDio(tokens);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await AuthRepository(dio, tokens).register(
      'grower_$stamp',
      'Grower',
      'grower_$stamp@example.com',
      'Fixture-passphrase-802!',
    );
    final farms = FarmRepository(dio), crops = CropRepository(dio);
    final farm = await farms.saveFarm({
      'name': 'Garden',
      'location': 'Tunis',
      'total_area': '5',
    });
    final field = await farms.saveField({
      'farm': farm.id,
      'name': 'East',
      'area': '2',
      'soil_type': 'loam',
    });
    final type = (await crops.types()).first;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    var cycle = await crops.save({
      'field': field.id,
      'crop_type': type.id,
      'variety': 'Local',
      'planting_date': today,
      'area': '1.50',
    });
    expect((await crops.cycles()).single.name, type.name);
    cycle = await crops.save({'current_stage': 'flowering'}, cycle.id);
    expect(cycle.stage, 'flowering');
    await expectLater(
      farms.deleteField(field.id),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          409,
        ),
      ),
    );
    await expectLater(
      crops.save({
        'field': field.id,
        'crop_type': type.id,
        'planting_date': today,
        'area': '1',
      }),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          400,
        ),
      ),
    );
    cycle = await crops.save({
      'status': 'completed',
      'end_date': today,
    }, cycle.id);
    expect(cycle.status, 'completed');
    final second = await crops.save({
      'field': field.id,
      'crop_type': type.id,
      'planting_date': today,
      'area': '1.50',
    });
    expect((await crops.cycles()).length, 2);
    await crops.delete(second.id);
    await crops.delete(cycle.id);
    await farms.deleteField(field.id);
    await farms.deleteFarm(farm.id);
  }, skip: !const bool.fromEnvironment('RUN_LIVE_API_TESTS'));
}
