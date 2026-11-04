import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../../core/data_revision.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);
final dashboardProvider = FutureProvider((ref) {
  ref.watch(signedInUserProvider);
  ref.watch(dataRevisionProvider);
  return ref.watch(dashboardRepositoryProvider).overview();
});
