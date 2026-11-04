import 'package:fieldbook/core/api.dart';
import 'package:fieldbook/features/auth/data/auth_repository.dart';
import 'package:fieldbook/features/farms/data/farm_repository.dart';
import 'package:fieldbook/features/weather/data/weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  test('Flutter weather configuration, placeholders, and Open-Meteo', () async {
    final tokens = MemoryTokens();
    final dio = createDio(tokens);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await AuthRepository(dio, tokens).register(
      'weather_$stamp',
      'Weather',
      'weather_$stamp@example.com',
      'Fixture-passphrase-802!',
    );
    final farm = await FarmRepository(dio).saveFarm({
      'name': 'Weather farm',
      'location': 'Tunis',
      'total_area': '4',
      'latitude': '36.8',
      'longitude': '10.18',
    });
    final repo = WeatherRepository(dio);
    expect((await repo.config()).enabled, isFalse);
    expect((await repo.weather(farm.id)).value('temperature'), '--');
    await repo.configure(enabled: true, mode: 'customer');
    expect((await repo.weather(farm.id)).status, 'not_configured');
    await repo.configure(enabled: true, mode: 'public');
    final weather = await repo.weather(farm.id, refresh: true);
    // Integration diagnostics distinguish a live provider success from fallback.
    // ignore: avoid_print
    print('Open-Meteo provider result: ${weather.status}');
    expect(['ok', 'unavailable'], contains(weather.status));
    if (weather.status == 'ok') {
      expect(weather.current['temperature'], isA<num>());
    } else {
      expect(weather.value('temperature'), '--');
    }
    await repo.configure(enabled: false, mode: 'public');
    expect((await repo.weather(farm.id)).value('temperature'), '--');
  }, skip: !const bool.fromEnvironment('RUN_LIVE_API_TESTS'));
}
