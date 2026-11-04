import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/crop_repository.dart';

final cropRepositoryProvider = Provider(
  (ref) => CropRepository(ref.watch(dioProvider)),
);
final cropTypesProvider = FutureProvider((ref) {
  ref.watch(signedInUserProvider);
  return ref.watch(cropRepositoryProvider).types();
});
final cyclesProvider = FutureProvider((ref) {
  ref.watch(signedInUserProvider);
  return ref.watch(cropRepositoryProvider).cycles();
});
