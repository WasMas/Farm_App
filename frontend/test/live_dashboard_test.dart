import 'package:fieldbook/core/api.dart';
import 'package:fieldbook/features/auth/data/auth_repository.dart';
import 'package:fieldbook/features/farms/data/farm_repository.dart';
import 'package:fieldbook/features/crops/data/crop_repository.dart';
import 'package:fieldbook/features/activities/data/activity_repository.dart';
import 'package:fieldbook/features/dashboard/data/dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  test(
    'Flutter dashboard reports persisted work and canonical units',
    () async {
      final tokens = MemoryTokens();
      final dio = createDio(tokens);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      await AuthRepository(dio, tokens).register(
        'summary_$stamp',
        'Summary',
        'summary_$stamp@example.com',
        'Fixture-passphrase-802!',
      );
      final farms = FarmRepository(dio),
          crops = CropRepository(dio),
          work = ActivityRepository(dio),
          dashboard = DashboardRepository(dio);
      expect((await dashboard.overview()).farms, 0);
      final farm = await farms.saveFarm({
        'name': 'Farm',
        'location': 'Tunis',
        'total_area': '4.5',
      });
      final field = await farms.saveField({
        'farm': farm.id,
        'name': 'South',
        'area': '2',
        'soil_type': 'loam',
      });
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final cycle = await crops.save({
        'field': field.id,
        'crop_type': (await crops.types()).first.id,
        'planting_date': date,
        'area': '2',
      });
      await work.save({
        'cycle': cycle.id,
        'kind': 'irrigation',
        'date': date,
        'quantity': '1500',
        'unit': 'l',
      });
      await work.save({
        'cycle': cycle.id,
        'kind': 'harvest',
        'date': date,
        'quantity': '2',
        'unit': 't',
      });
      final summary = await dashboard.overview();
      expect(summary.area, 4.5);
      expect(summary.activeCycles, 1);
      expect(summary.irrigation, 1.5);
      expect(summary.harvest, 2000);
      expect(summary.activitiesWeek, 2);
      expect(summary.recent.length, 2);
    },
    skip: !const bool.fromEnvironment('RUN_LIVE_API_TESTS'),
  );
}
