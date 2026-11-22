import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../../core/data_revision.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

class DashboardFarm extends Notifier<int?> {
  @override
  int? build() {
    ref.watch(signedInUserProvider);
    return null;
  }

  void select(int? farm) => state = farm;
}

final dashboardFarmProvider = NotifierProvider<DashboardFarm, int?>(
  DashboardFarm.new,
);
final dashboardProvider = FutureProvider((ref) {
  ref.watch(signedInUserProvider);
  ref.watch(dataRevisionProvider);
  return ref
      .watch(dashboardRepositoryProvider)
      .overview(ref.watch(dashboardFarmProvider));
});
