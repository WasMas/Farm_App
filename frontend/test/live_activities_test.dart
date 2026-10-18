import 'package:dio/dio.dart';
import 'package:fieldbook/core/api.dart';
import 'package:fieldbook/features/auth/data/auth_repository.dart';
import 'package:fieldbook/features/farms/data/farm_repository.dart';
import 'package:fieldbook/features/crops/data/crop_repository.dart';
import 'package:fieldbook/features/activities/data/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  test('Flutter records all work types, filters history, and protects planting history', () async {
    final tokens = MemoryTokens();
    final dio = createDio(tokens);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await AuthRepository(dio, tokens).register(
      'worker_$stamp',
      'Worker',
      'worker_$stamp@example.com',
      'Fixture-passphrase-802!',
    );
    final farms = FarmRepository(dio),
        crops = CropRepository(dio),
        activities = ActivityRepository(dio);
    final farm = await farms.saveFarm({
      'name': 'Farm',
      'location': 'Tunis',
      'total_area': '4',
    });
    final field = await farms.saveField({
      'farm': farm.id,
      'name': 'North',
      'area': '2',
      'soil_type': 'sandy',
    });
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cycle = await crops.save({
      'field': field.id,
      'crop_type': (await crops.types()).first.id,
      'planting_date': today,
      'area': '2',
    });
    for (final kind in [
      'irrigation',
      'fertilization',
      'treatment',
      'observation',
      'harvest',
    ]) {
      await activities.save({
        'cycle': cycle.id,
        'date': today,
        'kind': kind,
        'quantity': kind == 'observation' ? null : '12.5',
        'unit': kind == 'observation'
            ? ''
            : kind == 'irrigation'
            ? 'm3'
            : 'kg',
        'product': 'Test product',
        'notes': 'Recorded by live integration test.',
      });
    }
    expect((await activities.list()).length, 5);
    final harvest = (await activities.list(kind: 'harvest')).single;
    expect(harvest.amount, '12.5 kg');
    expect(
      (await activities.save({'quantity': '13.5'}, harvest.id)).quantity,
      13.5,
    );
    await expectLater(
      crops.delete(cycle.id),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          409,
        ),
      ),
    );
    await activities.delete(harvest.id);
    expect((await activities.list()).length, 4);
  }, skip: !const bool.fromEnvironment('RUN_LIVE_API_TESTS'));
}
