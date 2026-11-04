import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/weather_repository.dart';
import '../domain/weather_report.dart';

final weatherRepositoryProvider = Provider(
  (ref) => WeatherRepository(ref.watch(dioProvider)),
);
final weatherConfigProvider = FutureProvider((ref) {
  ref.watch(signedInUserProvider);
  return ref.watch(weatherRepositoryProvider).config();
});
final weatherProvider =
    FutureProvider.family<WeatherReport, ({int farm, int refresh})>((
      ref,
      query,
    ) async {
      ref.watch(signedInUserProvider);
      await ref.watch(weatherConfigProvider.future);
      return ref
          .watch(weatherRepositoryProvider)
          .weather(query.farm, refresh: query.refresh > 0);
    });
