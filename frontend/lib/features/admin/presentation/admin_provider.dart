import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);

final adminDashboardProvider = FutureProvider(
  (ref) => ref.watch(adminRepositoryProvider).dashboard(),
);

final adminAuditProvider = FutureProvider(
  (ref) => ref.watch(adminRepositoryProvider).audit(),
);
