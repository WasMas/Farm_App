import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/farm_repository.dart';

final farmRepositoryProvider = Provider(
  (ref) => FarmRepository(ref.watch(dioProvider)),
);
final farmsProvider = FutureProvider((ref) {
  ref.watch(authProvider);
  return ref.watch(farmRepositoryProvider).farms();
});
final farmProvider = FutureProvider.family((ref, int id) {
  ref.watch(authProvider);
  return ref.watch(farmRepositoryProvider).farm(id);
});
final fieldsProvider = FutureProvider.family((ref, int? id) {
  ref.watch(authProvider);
  return ref.watch(farmRepositoryProvider).fields(id);
});
final membersProvider = FutureProvider.family((ref, int id) {
  ref.watch(authProvider);
  return ref.watch(farmRepositoryProvider).members(id);
});
