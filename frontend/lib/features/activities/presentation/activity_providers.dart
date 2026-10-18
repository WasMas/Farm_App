import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/activity_repository.dart';

final activityRepositoryProvider = Provider(
  (ref) => ActivityRepository(ref.watch(dioProvider)),
);
final activitiesProvider = FutureProvider((ref) {
  ref.watch(authProvider);
  return ref.watch(activityRepositoryProvider).list();
});
